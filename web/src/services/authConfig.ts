import { AuthConfig } from "@urql/exchange-auth";
import { makeOperation } from "@urql/core";
import firebase from "@/services/firebase";

type AuthState = {
  token: string | null;
};

export const authConfig: AuthConfig<AuthState> = {
  getAuth: async () => {
    const token = await firebase.getIdToken();
    return { token };
  },
  willAuthError: () => {
    return true;
  },
  addAuthToOperation: ({ authState, operation }) => {
    if (!authState || !authState.token) {
      return operation;
    }

    const fetchOptions =
      typeof operation.context.fetchOptions === "function"
        ? operation.context.fetchOptions()
        : operation.context.fetchOptions || {};

    return makeOperation(operation.kind, operation, {
      ...operation.context,
      fetchOptions: {
        ...fetchOptions,
        headers: {
          ...fetchOptions.headers,
          Authorization: "Bearer " + authState.token,
        },
      },
    });
  },
};
