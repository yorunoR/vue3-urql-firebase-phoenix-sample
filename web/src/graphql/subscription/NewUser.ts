const SUBSCRIPTION = /* GraphQL */ `
  subscription NewUser {
    newUser {
      id
      name
    }
  }
`;
export default SUBSCRIPTION;
