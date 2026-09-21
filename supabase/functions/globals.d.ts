declare namespace Deno {
  function serve(handler: (req: Request) => Promise<Response> | Response): void;
  function readTextFile(path: string | URL): Promise<string>;
  function connectTls(options: {
    hostname: string;
    port: number;
    alpnProtocols?: string[];
  }): Promise<{
    alpnProtocol: string | null;
    close(): void;
  }>;
  const env: {
    get(key: string): string | undefined;
    set(key: string, value: string): void;
  };
  function test(name: string, fn: () => void | Promise<void>): void;
  namespace errors {
    class NotFound extends Error {}
  }
}

declare module "npm:cheerio@1.0.0" {
  export const load: any;
  const cheerio: any;
  export default cheerio;
}

declare module "npm:@supabase/supabase-js@2" {
  export const createClient: any;
  export type SupabaseClient = any;
  const client: any;
  export default client;
}

declare module "https://deno.land/std@0.224.0/assert/mod.ts" {
  export const assertEquals: any;
  export const assertNotEquals: any;
  export const assert: any;
}
