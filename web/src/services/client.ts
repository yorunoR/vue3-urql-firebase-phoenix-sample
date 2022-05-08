import {
  createClient,
  dedupExchange,
  cacheExchange,
  fetchExchange,
} from "@urql/vue";
import { authExchange } from "@urql/exchange-auth";
import { authConfig } from "@/services/authConfig";

const API_URL = process.env.VUE_APP_API_URL;

export function makeClient() {
  return createClient({
    url: `${API_URL}/api`,
    exchanges: [
      dedupExchange,
      cacheExchange,
      authExchange(authConfig),
      fetchExchange,
    ],
  });
}
