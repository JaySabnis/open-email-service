import { AuthClient } from "@dfinity/auth-client";

export const createAuthClient = () =>
  AuthClient.create({
    idleOptions: {
      disableIdle: true,
      disableDefaultIdleCallback: true,
    },
  });
