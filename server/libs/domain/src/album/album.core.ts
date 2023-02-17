import { AlbumEntity } from '@app/infra/db/entities';
import { ISearchRepository, SearchCollection } from '../search';
import { IAlbumRepository } from './album.repository';

export class AlbumCore {
  constructor(private searchRepository: ISearchRepository, private repository: IAlbumRepository) {}

  async save(album: Partial<AlbumEntity>): Promise<AlbumEntity> {
    const _album = await this.repository.save(album);
    this.searchRepository.index(SearchCollection.ALBUMS, _album);
    return _album;
  }
}
