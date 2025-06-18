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

        //hashmap <Principal, Profile>
        public var profiles : TrieMap.TrieMap<Principal, T.Profile> = TrieMap.TrieMap<Principal, T.Profile>(Principal.equal, Principal.hash);
        private var userAddressToIdMap : TrieMap.TrieMap<Text, Principal> = TrieMap.TrieMap<Text, Principal>(Text.equal, Text.hash);

        //create profile
        public func createProfile(caller : Principal, profileDTO : ProfileCommands.CreateProfileDTO) : T.ProfileResult {

            //validate data
            if (profileDTO.name.size() == 0 or profileDTO.surname.size() == 0) {
                return #err(#InvalidData("Name and surname cannot be empty"));
            };

            //validate description
            switch (profileDTO.description) {

                case (?text) if (text.size() > 1000) {
                    return #err(#InvalidData("Description should not exceed 1000 characters!."));
                };

                case _ {};
            };

            //check if user address is taken
            let isUserAddressTaken : Bool = not isUserAddressAvailable(profileDTO.userAddress);
            if (isUserAddressTaken) {
                return #err(#AlreadyExists("User address already taken. Please choose another. "));
            };

            //check if user has already registered
            let ifUserExist = profiles.get(caller);

            switch (ifUserExist) {

                case (?ifUserExist) {
                    return #err(#AlreadyExists("User with this id already exist!."));
                };

                case (null) {
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
            };
        };

        public func updateProfile(caller : Principal, profileDTO : ProfileCommands.UpdateProfileDTO) : Result.Result<T.Profile, T.ProfileError> {
            let savedProfile = profiles.get(caller);
            switch (savedProfile) {
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

                case (null) {
                    return #err(#NotFound);
                };
            };

        };

        public func getProfileInfoByUserAddress(userAddress : Text) : Result.Result<ProfileQueries.ProfileInfo,T.ProfileError> {
            switch (userAddressToIdMap.get(userAddress)) {
                case (?principalId) {
                    switch (profiles.get(principalId)) {
                        case (?profile) {
                            return #ok( {
                                id = principalId;
                                name = profile.name;
                                surname = profile.surname;
                                profileImage = profile.profileImage;
                            });
                        };
                        case null {
                            Debug.print("⚠️ No profile found for principal: " # Principal.toText(principalId));
                        };
                    };
                };
                case null {
                    Debug.print("⚠️ No principal found for address: " # userAddress);
                };
            };

            // Return fallback empty profile
            return #err(#NotFound);
        };

        //Get Profile
        public func getProfile(caller : Principal) : Result.Result<T.Profile, T.ProfileError> {
            let result = profiles.get(caller);
            switch (result) {
                case (?profile) {
                    return #ok(profile);
                };
                case (null) {
                    return #err(#NotFound);
                };
            };
        };

        //Get Principal Id using userAddress
        public func getPrincipalId(userAddress : Text) : ?Principal {
            let principalId : ?Principal = userAddressToIdMap.get(userAddress);
            return principalId;
        };

        //check if principal id is taken by someone
        public func isUserAddressAvailable(userAddress : Text) : Bool {
            switch (userAddressToIdMap.get(userAddress)) {
                case (?_) false;
                case null true;
            };
        };

        //Get Principal Id using userAddress
        public func getUserAddress(caller : Principal) : ?Text {
            let profile = profiles.get(caller);
            switch (profile) {
                case (?profile) ?profile.userAddress;
                case (null) null;
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
                case null {
                    #err(#NotFound);
                };
            };
        };

        public func setStableProfile(stableProfile : [(Principal, T.Profile)]) : () {

            for (profile : (Principal, T.Profile) in Iter.fromArray(stableProfile)) {
                profiles.put(profile.0, profile.1);
            };

        };

        public func setStableUserAddressStore(stableUserAddressStore : [(Text, Principal)]) : () {

            for (userAddress : (Text, Principal) in Iter.fromArray(stableUserAddressStore)) {
                userAddressToIdMap.put(userAddress.0, userAddress.1);
            };

        };

        public func getStableProfiles() : [(Principal, T.Profile)] {
            return Iter.toArray(profiles.entries());
        };

        public func getStableUserAddressStore() : [(Text, Principal)] {
            return Iter.toArray(userAddressToIdMap.entries());
        };

    };

};
