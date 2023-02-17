import { AssetSearchOptions, IAssetRepository } from '@app/domain';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AssetEntity } from '../entities';

export class AssetRepository implements IAssetRepository {
  constructor(@InjectRepository(AssetEntity) private repository: Repository<AssetEntity>) {}

  getAll(options?: AssetSearchOptions | undefined): Promise<AssetEntity[]> {
    options = options || {};

    return this.repository.find({
      where: {
        isVisible: options.isVisible,
      },
      relations: {
        exifInfo: true,
        smartInfo: true,
        tags: true,
      },
    });
  }

  async save(asset: AssetEntity) {
    const { id } = await this.repository.save(asset);
    return this.repository.findOneOrFail({ where: { id } });
  }
}
