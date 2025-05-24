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
      status: data?.status || null,
      name: data.name,
      description: data.description || null,
      surname: data.surname,
      userAddress: data.userAddress,
      profileImage: data?.profileImage || null,
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

  async updateProfile(data) {
    const identityActor = await ActorFactory.createIdentityActor(
      authStore,
      "bd3sg-teaaa-aaaaa-qaaba-cai",
    );

    let dto = {
      status: data.status || null, 
      name: data.name || null,
      description: data.description || null,
      surname: data.surname || null,
      profileImage: data.profileImage || null
    };

    const result = await identityActor.updateProfile(dto);
    return result;
  }

   async isUserAddressAvailable(userAddress){
    const identityActor = await ActorFactory.createIdentityActor(
      authStore,
      "bd3sg-teaaa-aaaaa-qaaba-cai",
    );
    let dto = {
      userAddress
    }
    const result = await identityActor.isUserAddressAvailable(userAddress);
    return result;
  }
  
}
