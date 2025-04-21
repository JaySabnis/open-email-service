import { createAuthClient } from "../utils/auth.utils";
import { AuthClient } from "@dfinity/auth-client";
import { writable } from "svelte/store";
import { AUTH_MAX_TIME_TO_LIVE} from '../constants/app.constants'

let authClient;

const initAuthStore = () => {
    const { subscribe, set, update } = writable({
        identity: undefined,
    });

    return {
        subscribe,

        sync: async () => {
            authClient = authClient ?? (await createAuthClient());
            const isAuthenticated = await authClient.isAuthenticated();

            set({
                identity: isAuthenticated ? authClient.getIdentity() : null,
            });
        },

        signIn: ({ domain }) =>
            // eslint-disable-next-line no-async-promise-executor
            new Promise(async (resolve, reject) => {
                authClient = authClient ?? (await createAuthClient());
                const identityProvider = domain;

                await authClient?.login({
                    maxTimeToLive: AUTH_MAX_TIME_TO_LIVE,
                    onSuccess: () => {
                        update((state) => ({
                            ...state,
                            identity: authClient?.getIdentity(),
                        }));

                        resolve();
                    },
                    onError: reject,
                    identityProvider,
                });
            }),

        signOut: async () => {
            const client = authClient ?? (await createAuthClient());

            await client.logout();

            authClient = null;

            update((state) => ({
                ...state,
                identity: null,
            }));
            localStorage.removeItem("user_profile_data");
        },
    };
};

export const authStore = initAuthStore();