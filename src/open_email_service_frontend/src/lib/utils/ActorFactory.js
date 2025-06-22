import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory as backend_canister } from '../../../../declarations/backend/backend.did.js'

export class ActorFactory {
  static createActor(
    idlFactory,
    canisterId = "",
    identity = null,
    options = null,
  ) {
    const hostOptions = {
      // host:`http://localhost:4943/?canisterId=qhbym-qaaaa-aaaaa-aaafq-cai`,
      host: `https://5p73d-fiaaa-aaaaa-qauwa-cai.icp0.io/`,
      identity,
    };

    if (!options) {
      options = {
        agentOptions: hostOptions,
      };
    } else if (!options.agentOptions) {
      options.agentOptions = hostOptions;
    } else {
      options.agentOptions.host = hostOptions.host;
    }

    const agent = new HttpAgent({ ...options.agentOptions });

    //Note: do not deploy to mainnet
      // agent.fetchRootKey().catch((err) => {
      //   console.warn(
      //     "Unable to fetch root key. Ensure your local replica is running",
      //   );
      //   console.error(err);
      // });

    return Actor.createActor(idlFactory, {
      agent,
      canisterId: canisterId,
      ...options?.actorOptions,
    });
  }

  static createIdentityActor(authStore, canisterId) {
    let unsubscribe;
    return new Promise((resolve, reject) => {
      unsubscribe = authStore.subscribe((store) => {
        if (store.identity) {
          resolve(store.identity);
        }
      });
    }).then((identity) => {
      unsubscribe();
      return ActorFactory.createActor(backend_canister, canisterId, identity);
    });
  }

}
