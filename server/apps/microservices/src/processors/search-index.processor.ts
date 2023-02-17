import { ISearchIndexAlbumJob, ISearchIndexAssetJob, JobName, QueueName, SearchService } from '@app/domain';
import { Process, Processor } from '@nestjs/bull';
import { Job } from 'bull';

@Processor(QueueName.SEARCH_INDEX)
export class SearchIndexProcessor {
  constructor(private searchService: SearchService) {}

  @Process({ name: JobName.SEARCH_INDEX_ASSETS, concurrency: 1 })
  async indexAssets() {
    await this.searchService.indexAssets();
  }

  @Process({ name: JobName.SEARCH_INDEX_ASSET, concurrency: 1 })
  async indexAsset(job: Job<ISearchIndexAssetJob>) {
    await this.searchService.indexAsset(job.data.asset);
  }

  @Process({ name: JobName.SEARCH_INDEX_ALBUMS, concurrency: 1 })
  async indexAlbums() {
    await this.searchService.indexAlbums();
  }

  @Process({ name: JobName.SEARCH_INDEX_ALBUM, concurrency: 1 })
  async indexAlbum(job: Job<ISearchIndexAlbumJob>) {
    await this.searchService.indexAlbum(job.data.album);
  }
}
