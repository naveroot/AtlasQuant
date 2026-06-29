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

  private async request<T>(path: string, init?: RequestInit): Promise<T> {
    const response = await fetch(this.api(path), {
      ...init,
      headers: {
        "X-API-Key": this.apiKey,
        "Content-Type": "application/json",
        ...init?.headers,
      },
    });

    if (!response.ok) {
      const body = await response.text();
      throw new Error(`Plane API ${response.status}: ${body}`);
    }

    return response.json() as Promise<T>;
  }

  async listWorkItems(expand = "labels,state"): Promise<PlaneWorkItem[]> {
    const items: PlaneWorkItem[] = [];
    let cursor: string | undefined;

    do {
      const params = new URLSearchParams({ expand, per_page: "100" });
      if (cursor) params.set("cursor", cursor);

      const page = await this.request<PlaneWorkItemList>(
        `/workspaces/${this.workspace}/projects/${this.projectId}/work-items/?${params}`,
      );

      items.push(...(page.results ?? []));
      cursor = page.next_cursor;
    } while (cursor);

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
