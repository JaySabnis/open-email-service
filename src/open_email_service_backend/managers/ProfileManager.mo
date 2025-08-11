import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Option "mo:base/Option";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import Debug "mo:base/Debug";

import T "../types/ProfileTypes";
import ProfileCommands "../commands/ProfileCommands";
import ProfileQueries "../queries/ProfileQueries";

module {

  public class ProfileManager() {

    // Optimized storage using TrieMap for O(1) operations
    private var profiles : TrieMap.TrieMap<Principal, T.Profile> = TrieMap.TrieMap<Principal, T.Profile>(Principal.equal, Principal.hash);
    private var userAddressToIdMap : TrieMap.TrieMap<Text, Principal> = TrieMap.TrieMap<Text, Principal>(Text.equal, Text.hash);

    // Helper function to validate profile data
    private func validateProfileData(profileDTO : ProfileCommands.CreateProfileDTO) : Result.Result<(), T.ProfileError> {
      if (profileDTO.name.size() == 0 or profileDTO.surname.size() == 0) {
        return #err(#InvalidData("Name and surname cannot be empty"));
      };

      switch (profileDTO.description) {
        case (?text) if (text.size() > 1000) {
          return #err(#InvalidData("Description should not exceed 1000 characters!."));
        };
        case _ {};
      };

      #ok();
    };

    //create profile
    public func createProfile(caller : Principal, profileDTO : ProfileCommands.CreateProfileDTO) : T.ProfileResult {
      // Validate data first
      switch (validateProfileData(profileDTO)) {
        case (#err(error)) return #err(error);
        case (#ok) {};
      };

      // Check if user address is taken
      if (not isUserAddressAvailable(profileDTO.userAddress)) {
        return #err(#AlreadyExists("User address already taken. Please choose another. "));
      };

      // Check if user has already registered
      if (profiles.get(caller) != null) {
        return #err(#AlreadyExists("User with this id already exist!."));
      };

      let saveProfile : T.Profile = {
        id = caller;
        name = profileDTO.name;
        surname = profileDTO.surname;
        userAddress = profileDTO.userAddress;
        status = profileDTO.status;
        description = profileDTO.description;
        profileImage = profileDTO.profileImage;
        createdOn = Time.now();
        modifiedOn = Time.now();
      };

      profiles.put(caller, saveProfile);
      userAddressToIdMap.put(profileDTO.userAddress, caller);
      return #ok;
    };

    public func updateProfile(caller : Principal, profileDTO : ProfileCommands.UpdateProfileDTO) : Result.Result<T.Profile, T.ProfileError> {
      switch (profiles.get(caller)) {
        case (?profile) {
          let updatedProfile : T.Profile = {
            id = profile.id;
            name = Option.get(profileDTO.name, profile.name);
            surname = Option.get(profileDTO.surname, profile.surname);
            userAddress = profile.userAddress;
            status = ?Option.get(profileDTO.status, "");
            description = ?Option.get(profileDTO.description, "");
            profileImage = ?Option.get(profileDTO.profileImage, Blob.fromArray([]));
            createdOn = profile.createdOn;
            modifiedOn = Time.now();
          };

          profiles.put(caller, updatedProfile);
          return #ok(updatedProfile);
        };
        case null return #err(#NotFound);
      };
    };

    public func getProfileInfoByUserAddress(userAddress : Text) : Result.Result<ProfileQueries.ProfileInfo, T.ProfileError> {
      switch (userAddressToIdMap.get(userAddress)) {
        case (?principalId) {
          switch (profiles.get(principalId)) {
            case (?profile) {
              return #ok({
                id = principalId;
                name = profile.name;
                surname = profile.surname;
                profileImage = profile.profileImage;
              });
            };
            case null {
              Debug.print("⚠️ No profile found for principal: " # Principal.toText(principalId));
              return #err(#NotFound);
            };
          };
        };
        case null {
          Debug.print("⚠️ No principal found for address: " # userAddress);
          return #err(#NotFound);
        };
      };
    };

    //Get Profile
    public func getProfile(caller : Principal) : Result.Result<T.Profile, T.ProfileError> {
      switch (profiles.get(caller)) {
        case (?profile) return #ok(profile);
        case null return #err(#NotFound);
      };
    };

    //Get Principal Id using userAddress
    public func getPrincipalId(userAddress : Text) : ?Principal {
      userAddressToIdMap.get(userAddress);
    };

    //check if principal id is taken by someone
    public func isUserAddressAvailable(userAddress : Text) : Bool {
      userAddressToIdMap.get(userAddress) == null;
    };

    //Get Principal Id using userAddress
    public func getUserAddress(caller : Principal) : ?Text {
      switch (profiles.get(caller)) {
        case (?profile) ?profile.userAddress;
        case null null;
      };
    };

    //Delete Profile
    public func deleteProfile(caller : Principal) : T.ProfileResult {
      switch (profiles.get(caller)) {
        case (?profile) {
          userAddressToIdMap.delete(profile.userAddress);
          profiles.delete(caller);
          #ok;
        };
        case null #err(#NotFound);
      };
    };

    // Optimized stable storage methods
    public func setStableProfile(stableProfile : [(Principal, T.Profile)]) : () {
      for (profile in stableProfile.vals()) {
        profiles.put(profile.0, profile.1);
      };
    };

    public func setStableUserAddressStore(stableUserAddressStore : [(Text, Principal)]) : () {
      for (userAddress in stableUserAddressStore.vals()) {
        userAddressToIdMap.put(userAddress.0, userAddress.1);
      };
    };

    public func getStableProfiles() : [(Principal, T.Profile)] {
      Iter.toArray(profiles.entries());
    };

    public func getStableUserAddressStore() : [(Text, Principal)] {
      Iter.toArray(userAddressToIdMap.entries());
    };

  };

};
