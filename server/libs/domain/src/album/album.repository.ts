import { AlbumEntity } from '@app/infra/db/entities';

export const IAlbumRepository = 'IAlbumRepository';

export interface IAlbumRepository {
  getAll(): Promise<AlbumEntity[]>;
  save(album: Partial<AlbumEntity>): Promise<AlbumEntity>;
}
