import gql from "graphql-tag";
import * as Urql from "@urql/vue";
export type Maybe<T> = T | null;
export type InputMaybe<T> = Maybe<T>;
export type Exact<T extends { [key: string]: unknown }> = {
  [K in keyof T]: T[K];
};
export type MakeOptional<T, K extends keyof T> = Omit<T, K> & {
  [SubKey in K]?: Maybe<T[SubKey]>;
};
export type MakeMaybe<T, K extends keyof T> = Omit<T, K> & {
  [SubKey in K]: Maybe<T[SubKey]>;
};
export type Omit<T, K extends keyof T> = Pick<T, Exclude<keyof T, K>>;
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: string;
  String: string;
  Boolean: boolean;
  Int: number;
  Float: number;
};

export type RootQueryType = {
  __typename?: "RootQueryType";
  ping?: Maybe<Status>;
};

export type Status = {
  __typename?: "Status";
  status?: Maybe<Scalars["Boolean"]>;
};

export type PingQueryVariables = Exact<{ [key: string]: never }>;

export type PingQuery = {
  __typename?: "RootQueryType";
  ping?: { __typename?: "Status"; status?: boolean | null } | null;
};

export const PingDocument = gql`
  query Ping {
    ping {
      status
    }
  }
`;

export function usePingQuery(
  options: Omit<Urql.UseQueryArgs<never, PingQueryVariables>, "query"> = {}
) {
  return Urql.useQuery<PingQuery>({ query: PingDocument, ...options });
}
