import {
  ISearchRepository,
  SearchCollection,
  SearchCollectionIndexStatus,
  SearchFilter,
  SearchResult,
} from '@app/domain';
import { Injectable, Logger } from '@nestjs/common';
import { Client } from 'typesense';
import { CollectionCreateSchema } from 'typesense/lib/Typesense/Collections';
import { DocumentSchema, SearchResponse } from 'typesense/lib/Typesense/Documents';
import { AlbumEntity, AssetEntity } from '../db';
import { albumSchema } from './schemas/album.schema';
import { assetSchema } from './schemas/asset.schema';

const schemaMap: Record<SearchCollection, CollectionCreateSchema> = {
  [SearchCollection.ASSETS]: assetSchema,
  [SearchCollection.ALBUMS]: albumSchema,
};

const schemas = Object.entries(schemaMap) as [SearchCollection, CollectionCreateSchema][];

// TODO: look at using an external file for advanced configuration
export const typesense = new Client({
  nodes: [
    {
      host: process.env.TYPESENSE_HOST || 'typesense',
      port: Number(process.env.TYPESENSE_PORT) || 8108,
      protocol: process.env.TYPESENSE_PROTOCOL || 'http',
    },
  ],
  apiKey: process.env.TYPESENSE_API_KEY || 'should-not-be-used',
  numRetries: 3,
  connectionTimeoutSeconds: 10,
});

@Injectable()
export class TypesenseRepository implements ISearchRepository {
  private client = typesense;
  private logger = new Logger(TypesenseRepository.name);
  private queue: Record<SearchCollection, any[]> = {
    [SearchCollection.ASSETS]: [],
    [SearchCollection.ALBUMS]: [],
  };

  constructor() {
    setInterval(() => this.flush(), 5_000);
  }

  async setup(): Promise<void> {
    // upsert collections
    for (const [collectionName, schema] of schemas) {
      const collection = await this.client
        .collections(schema.name)
        .retrieve()
        .catch(() => null);
      if (!collection) {
        this.logger.log(`Creating schema: ${collectionName}/${schema.name}`);
        await this.client.collections().create(schema);
      } else {
        this.logger.log(`Schema up to date: ${collectionName}/${schema.name}`);
      }
    }
  }

  async checkMigrationStatus(): Promise<SearchCollectionIndexStatus> {
    const migrationMap: SearchCollectionIndexStatus = {
      [SearchCollection.ASSETS]: false,
      [SearchCollection.ALBUMS]: false,
    };

    // check if alias is using the current schema
    const { aliases } = await this.client.aliases().retrieve();
    this.logger.log(`Alias mapping: ${JSON.stringify(aliases)}`);

    for (const [aliasName, schema] of schemas) {
      const match = aliases.find((alias) => alias.name === aliasName);
      if (!match || match.collection_name !== schema.name) {
        migrationMap[aliasName] = true;
      }
    }

    this.logger.log(`Collections needing migration: ${JSON.stringify(migrationMap)}`);

    return migrationMap;
  }

  async index(collection: SearchCollection, item: AssetEntity | AlbumEntity, immediate?: boolean): Promise<void> {
    const schema = schemaMap[collection];

    if (immediate) {
      await this.client.collections(schema.name).documents().upsert(item);
      return;
    }

    this.queue[collection].push(item);
  }

  async import(collection: SearchCollection, items: AssetEntity[] | AlbumEntity[], done: boolean): Promise<void> {
    try {
      const schema = schemaMap[collection];
      await this.client.collections(schema.name).documents().import(items, { action: 'upsert' });
      if (done) {
        await this.updateAlias(collection);
      }
    } catch (error: any) {
      this.logger.error('Unable to index asset documents', error.importResults);
      throw error;
    }
  }

  search(collection: SearchCollection.ASSETS, query: string, filter: SearchFilter): Promise<SearchResult<AssetEntity>>;
  search(collection: SearchCollection.ALBUMS, query: string, filter: SearchFilter): Promise<SearchResult<AlbumEntity>>;
  async search(collection: SearchCollection, query: string, filters: SearchFilter) {
    const alias = await this.client.aliases(collection).retrieve();

    const { userId } = filters;

    if (collection === SearchCollection.ASSETS) {
      const results = await this.client
        .collections<AssetEntity>(alias.collection_name)
        .documents()
        .search({
          q: query,
          query_by: 'originalPath',
          filter_by: `userId:${userId}`,
        });

      return this.asResponse(results);
    }

    if (collection === SearchCollection.ALBUMS) {
      const results = await this.client
        .collections<AlbumEntity>(alias.collection_name)
        .documents()
        .search({
          q: query,
          query_by: 'originalPath',
          filter_by: `userId:${userId}`,
        });

      return this.asResponse(results);
    }

    throw new Error(`Invalid collection: ${collection}`);
  }

  private asResponse<T extends DocumentSchema>(results: SearchResponse<T>): SearchResult<T> {
    return {
      page: results.page,
      items: (results.hits || []).map((hit) => hit.document),
    };
  }

  private async flush() {
    for (const [collection, schema] of schemas) {
      if (this.queue[collection].length > 0) {
        await this.client.collections(schema.name).documents().import(this.queue[collection], { action: 'upsert' });
        this.queue[collection] = [];
      }
    }
  }

  private async updateAlias(collection: SearchCollection) {
    const schema = schemaMap[collection];
    const alias = await this.client
      .aliases(collection)
      .retrieve()
      .catch(() => null);

    // update alias to current collection
    this.logger.log(`Using new schema: ${alias?.collection_name || '(unset)'} => ${schema.name}`);
    await this.client.aliases().upsert(collection, { collection_name: schema.name });

    // delete previous collection
    if (alias && alias.collection_name !== schema.name) {
      this.logger.log(`Deleting old schema: ${alias.collection_name}`);
      await this.client.collections(alias.collection_name).delete();
    }
  }
}
