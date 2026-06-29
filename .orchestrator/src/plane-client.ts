export interface PlaneLabel {
  id: string;
  name: string;
}

export interface PlaneState {
  id: string;
  name: string;
  group: string;
}

export interface PlaneWorkItem {
  id: string;
  name: string;
  sequence_id: number;
  description_stripped: string;
  description_html: string;
  labels: PlaneLabel[];
  state: PlaneState | string;
  project_identifier?: string;
}

export interface PlaneWorkItemList {
  results: PlaneWorkItem[];
  next_cursor?: string;
}

export class PlaneClient {
  constructor(
    private readonly baseUrl: string,
    private readonly apiKey: string,
    private readonly workspace: string,
    private readonly projectId: string,
  ) {}

  private api(path: string): string {
    return `${this.baseUrl.replace(/\/$/, "")}/api/v1${path}`;
  }

  private async request<T>(
    path: string,
    init?: RequestInit,
    attempt = 1,
  ): Promise<T> {
    const maxAttempts = 5;
    const response = await fetch(this.api(path), {
      ...init,
      headers: {
        "X-API-Key": this.apiKey,
        "Content-Type": "application/json",
        ...init?.headers,
      },
    });

    if (response.status === 429 && attempt < maxAttempts) {
      const retryAfterHeader = response.headers.get("Retry-After");
      const retrySeconds = retryAfterHeader
        ? Number.parseInt(retryAfterHeader, 10)
        : 30;
      const waitMs = (Number.isFinite(retrySeconds) ? retrySeconds : 30) * 1000;
      console.log(
        `Plane rate limit (429), retry in ${Math.ceil(waitMs / 1000)}s (attempt ${attempt}/${maxAttempts})`,
      );
      await new Promise((resolve) => setTimeout(resolve, waitMs));
      return this.request(path, init, attempt + 1);
    }

    if (!response.ok) {
      const body = await response.text();
      throw new Error(`Plane API ${response.status}: ${body}`);
    }

    return response.json() as Promise<T>;
  }

  async listWorkItems(expand = "labels,state"): Promise<PlaneWorkItem[]> {
    const items: PlaneWorkItem[] = [];
    let cursor: string | undefined;
    const perPage = 100;

    do {
      const params = new URLSearchParams({ expand, per_page: String(perPage) });
      if (cursor) params.set("cursor", cursor);

      const page = await this.request<PlaneWorkItemList>(
        `/workspaces/${this.workspace}/projects/${this.projectId}/work-items/?${params}`,
      );

      const batch = page.results ?? [];
      items.push(...batch);

      // Plane always returns next_cursor even on the last page — stop when the page is short.
      if (batch.length < perPage) break;
      cursor = page.next_cursor;
      if (!cursor) break;
    } while (true);

    return items;
  }

  async getWorkItem(issueId: string): Promise<PlaneWorkItem> {
    return this.request<PlaneWorkItem>(
      `/workspaces/${this.workspace}/projects/${this.projectId}/work-items/${issueId}/?expand=labels,state`,
    );
  }

  async addComment(issueId: string, commentHtml: string): Promise<void> {
    await this.request(
      `/workspaces/${this.workspace}/projects/${this.projectId}/work-items/${issueId}/comments/`,
      {
        method: "POST",
        body: JSON.stringify({ comment_html: commentHtml }),
      },
    );
  }

  filterAgentReady(items: PlaneWorkItem[], labelId: string): PlaneWorkItem[] {
    return items.filter((item) => {
      const labels = item.labels ?? [];
      return labels.some((l) => l.id === labelId);
    });
  }
}
