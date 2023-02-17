import { AssetEntity } from '@app/infra/db/entities';
import { ISearchRepository, SearchCollection } from '../search';
import { AssetSearchOptions, IAssetRepository } from './asset.repository';

export class AssetCore {
  constructor(private repository: IAssetRepository, private searchRepository: ISearchRepository) {}

  getAll(options: AssetSearchOptions) {
    return this.repository.getAll(options);
  }

  async save(asset: Partial<AssetEntity>) {
    const _asset = await this.repository.save(asset);
    await this.searchRepository.index(SearchCollection.ASSETS, _asset);
    return _asset;
  }
}
