import { ActorFactory } from "../utils/ActorFactory";
import { authStore } from "../store/auth-store";

export class ProfileService {
  constructor() { }

  async createProfile(data) {
    const identityActor = await ActorFactory.createIdentityActor(
      authStore,
      "bd3sg-teaaa-aaaaa-qaaba-cai",
    );

    let dto = {
      status: data.status != null ? [data.status] : [],
      name: data.name,
      description: data.description != null ? [data.description] : [],
      surname: data.surname,
      userAddress: data.userAddress,
      profileImage: []
    };

    const result = await identityActor.createProfile(dto);
    return result;
  }

  async getProfile() {
    const identityActor = await ActorFactory.createIdentityActor(
      authStore,
      "bd3sg-teaaa-aaaaa-qaaba-cai",
    );
    const result = await identityActor.getProfile();
    return result;
  }

  async updateProfile() {
    const identityActor = await ActorFactory.createIdentityActor(
      authStore,
      "bd3sg-teaaa-aaaaa-qaaba-cai",
    );

    let dto = {
      status: data.status != null ? [data.status] : [],
      name: data.name,
      description: data.description != null ? [data.description] : [],
      surname: data.surname,
      profileImage: []
    };

    const result = await identityActor.updateProfile(dto);
    return result;
  }

}
