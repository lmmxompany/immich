import { AssetEntity } from '@app/infra/db/entities';

export const IAssetRepository = 'IAssetRepository';

export interface AssetSearchOptions {
  isVisible?: boolean;
}

export interface IAssetRepository {
  getAll(options?: AssetSearchOptions): Promise<AssetEntity[]>;
  save(asset: Partial<AssetEntity>): Promise<AssetEntity>;
}
