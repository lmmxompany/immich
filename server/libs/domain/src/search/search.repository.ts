import { AlbumEntity, AssetEntity } from '@app/infra/db/entities';

export enum SearchCollection {
  ASSETS = 'assets',
  ALBUMS = 'albums',
}

export interface SearchFilter {
  userId: string;
}

export interface SearchResult<T> {
  page: number;
  items: T[];
}

export type SearchCollectionIndexStatus = Record<SearchCollection, boolean>;

export const ISearchRepository = 'ISearchRepository';

export interface ISearchRepository {
  setup(): Promise<void>;
  checkMigrationStatus(): Promise<SearchCollectionIndexStatus>;

  index(collection: SearchCollection.ASSETS, item: AssetEntity): Promise<void>;
  index(collection: SearchCollection.ALBUMS, item: AlbumEntity): Promise<void>;

  import(collection: SearchCollection.ASSETS, items: AssetEntity[], done: boolean): Promise<void>;
  import(collection: SearchCollection.ALBUMS, items: AlbumEntity[], done: boolean): Promise<void>;

  search(collection: SearchCollection.ASSETS, query: string, filters: SearchFilter): Promise<SearchResult<AssetEntity>>;
  search(collection: SearchCollection.ALBUMS, query: string, filters: SearchFilter): Promise<SearchResult<AlbumEntity>>;
}
