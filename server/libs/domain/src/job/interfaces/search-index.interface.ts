import { AlbumEntity, AssetEntity } from '@app/infra/db/entities';

export interface ISearchIndexAssetJob {
  asset: AssetEntity;
}

export interface ISearchIndexAlbumJob {
  album: AlbumEntity;
}
