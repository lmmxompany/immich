import { IAlbumRepository } from '@app/domain';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AlbumEntity } from '../entities';

export class AlbumRepository implements IAlbumRepository {
  constructor(@InjectRepository(AlbumEntity) private repository: Repository<AlbumEntity>) {}

  getAll(): Promise<AlbumEntity[]> {
    return this.repository.find();
  }

  async save(album: Partial<AlbumEntity>) {
    const { id } = await this.repository.save(album);
    return this.repository.findOneOrFail({ where: { id } });
  }
}
