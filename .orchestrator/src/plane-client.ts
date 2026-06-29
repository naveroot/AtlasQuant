export class PlaneApiError extends Error {
  readonly status: number;
  readonly retryAfterSeconds?: number;

  constructor(message: string, status: number, retryAfterSeconds?: number) {
    super(message);
    this.name = "PlaneApiError";
    this.status = status;
    this.retryAfterSeconds = retryAfterSeconds;
  }

  get isRateLimited(): boolean {
    return this.status === 429;
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function parseRetryAfter(header: string | null): number | undefined {
  if (!header) return undefined;
  const seconds = Number.parseInt(header, 10);
  if (!Number.isNaN(seconds)) return seconds;
  const date = Date.parse(header);
  if (!Number.isNaN(date)) {
    return Math.max(0, Math.ceil((date - Date.now()) / 1000));
  }
  return undefined;
}

export interface PlaneLabel {
  id: string;
  name: string;
}

export interface PlaneState {
  id: string;
  name: string;
  group: string;
  color?: string;
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

export interface PlaneStateList {
  results: PlaneState[];
  next_cursor?: string;
}

export type PlaneStateGroup =
  | "backlog"
  | "unstarted"
  | "started"
  | "completed"
  | "cancelled";

export interface PlaneClientOptions {
  /** Max retries on 429 (default: 5) */
  rateLimitMaxRetries?: number;
  /** Base delay ms for exponential backoff (default: 2000) */
  rateLimitBaseDelayMs?: number;
}

export function getWorkItemStateId(item: PlaneWorkItem): string | undefined {
  const state = item.state;
  if (!state) return undefined;
  if (typeof state === "string") return state;
  return state.id;
}

export function getWorkItemStateName(item: PlaneWorkItem): string | undefined {
  const state = item.state;
  if (!state) return undefined;
  if (typeof state === "string") return state;
  return state.name;
}

export class PlaneClient {
  private readonly rateLimitMaxRetries: number;
  private readonly rateLimitBaseDelayMs: number;

  constructor(
    private readonly baseUrl: string,
    private readonly apiKey: string,
    private readonly workspace: string,
    private readonly projectId: string,
    options: PlaneClientOptions = {},
  ) {
    this.rateLimitMaxRetries = options.rateLimitMaxRetries ?? 5;
    this.rateLimitBaseDelayMs = options.rateLimitBaseDelayMs ?? 2000;
  }

  private api(path: string): string {
    return `${this.baseUrl.replace(/\/$/, "")}/api/v1${path}`;
  }

  private async request<T>(
    path: string,
    init?: RequestInit,
    attempt = 0,
  ): Promise<T> {
    const response = await fetch(this.api(path), {
      ...init,
      headers: {
        "X-API-Key": this.apiKey,
        "Content-Type": "application/json",
        ...init?.headers,
      },
    });

    if (response.status === 429 && attempt < this.rateLimitMaxRetries) {
      const retryAfter = parseRetryAfter(response.headers.get("Retry-After"));
      const delayMs =
        retryAfter !== undefined
          ? retryAfter * 1000
          : this.rateLimitBaseDelayMs * 2 ** attempt;

      console.warn(
        `Plane rate limit (429), retry in ${Math.round(delayMs / 1000)}s ` +
          `(attempt ${attempt + 1}/${this.rateLimitMaxRetries})`,
      );
      await sleep(delayMs);
      return this.request<T>(path, init, attempt + 1);
    }

    if (!response.ok) {
      const body = await response.text();
      const retryAfter = parseRetryAfter(response.headers.get("Retry-After"));
      throw new PlaneApiError(
        `Plane API ${response.status}: ${body}`,
        response.status,
        retryAfter,
      );
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

  async listStates(): Promise<PlaneState[]> {
    const states: PlaneState[] = [];
    let cursor: string | undefined;

    do {
      const params = new URLSearchParams({ per_page: "100" });
      if (cursor) params.set("cursor", cursor);

      const page = await this.request<PlaneStateList | PlaneState[]>(
        `/workspaces/${this.workspace}/projects/${this.projectId}/states/?${params}`,
      );

      const batch = Array.isArray(page) ? page : (page.results ?? []);
      states.push(...batch);
      cursor = Array.isArray(page) ? undefined : page.next_cursor;
    } while (cursor);

    return states;
  }

  async createState(
    name: string,
    group: PlaneStateGroup,
    color: string,
  ): Promise<PlaneState> {
    return this.request<PlaneState>(
      `/workspaces/${this.workspace}/projects/${this.projectId}/states/`,
      {
        method: "POST",
        body: JSON.stringify({ name, group, color }),
      },
    );
  }

  async updateWorkItemState(
    issueId: string,
    stateId: string,
  ): Promise<PlaneWorkItem> {
    return this.request<PlaneWorkItem>(
      `/workspaces/${this.workspace}/projects/${this.projectId}/work-items/${issueId}/`,
      {
        method: "PATCH",
        body: JSON.stringify({ state: stateId }),
      },
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

  filterByState(items: PlaneWorkItem[], stateId: string): PlaneWorkItem[] {
    return items.filter((item) => getWorkItemStateId(item) === stateId);
  }

  findStateByName(states: PlaneState[], name: string): PlaneState | undefined {
    return states.find((s) => s.name.toLowerCase() === name.toLowerCase());
  }

  /** @deprecated Use filterByState with plane.states.ready instead */
  filterAgentReady(items: PlaneWorkItem[], labelId: string): PlaneWorkItem[] {
    return items.filter((item) => {
      const labels = item.labels ?? [];
      return labels.some((l) => l.id === labelId);
    });
  }
}
