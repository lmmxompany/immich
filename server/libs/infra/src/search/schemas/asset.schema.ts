import { CollectionCreateSchema } from 'typesense/lib/Typesense/Collections';

export const assetSchemaVersion = 7;
export const assetSchema: CollectionCreateSchema = {
  name: `assets-v${assetSchemaVersion}`,
  fields: [
    { name: 'userId', type: 'string', facet: false },
    { name: 'type', type: 'string', facet: true },
    { name: 'originalPath', type: 'string', facet: false },
    { name: 'createdAt', type: 'string', facet: false, sort: true },
    { name: 'modifiedAt', type: 'string', facet: false },
    { name: 'updatedAt', type: 'string', facet: false },
    { name: 'isFavorite', type: 'bool', facet: true },
    // { name: 'checksum', type: 'string', facet: true },
    { name: 'tags', type: 'string[]', facet: true },
  ],
  default_sorting_field: 'createdAt',
};
