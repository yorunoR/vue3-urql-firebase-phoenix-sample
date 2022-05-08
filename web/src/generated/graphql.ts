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

export type RootSubscriptionType = {
  __typename?: "RootSubscriptionType";
  newUser?: Maybe<User>;
};

export type Status = {
  __typename?: "Status";
  status?: Maybe<Scalars["Boolean"]>;
};

export type User = {
  __typename?: "User";
  activated?: Maybe<Scalars["Boolean"]>;
  email?: Maybe<Scalars["String"]>;
  id?: Maybe<Scalars["ID"]>;
  name?: Maybe<Scalars["String"]>;
  profileImage?: Maybe<Scalars["String"]>;
  role?: Maybe<Scalars["Int"]>;
  uid?: Maybe<Scalars["String"]>;
};

export type PingQueryVariables = Exact<{ [key: string]: never }>;

export type PingQuery = {
  __typename?: "RootQueryType";
  ping?: { __typename?: "Status"; status?: boolean | null } | null;
};

export type NewUserSubscriptionVariables = Exact<{ [key: string]: never }>;

export type NewUserSubscription = {
  __typename?: "RootSubscriptionType";
  newUser?: {
    __typename?: "User";
    id?: string | null;
    name?: string | null;
  } | null;
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
export const NewUserDocument = gql`
  subscription NewUser {
    newUser {
      id
      name
    }
  }
`;

export function useNewUserSubscription<R = NewUserSubscription>(
  options: Omit<
    Urql.UseSubscriptionArgs<never, NewUserSubscriptionVariables>,
    "query"
  > = {},
  handler?: Urql.SubscriptionHandlerArg<NewUserSubscription, R>
) {
  return Urql.useSubscription<
    NewUserSubscription,
    R,
    NewUserSubscriptionVariables
  >({ query: NewUserDocument, ...options }, handler);
}
