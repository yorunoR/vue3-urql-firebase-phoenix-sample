import { createClient } from "@urql/vue";

const API_URL = process.env.VUE_APP_API_URL;

export function makeClient() {
  return createClient({ url: `${API_URL}/api` });
}
