import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Option "mo:base/Option";
import Blob "mo:base/Blob";


import T "Types";

module{

    public class ProfileManager(){

        //hashmap <Principal, Profile>
        public var profiles:TrieMap.TrieMap<Principal,T.Profile> = TrieMap.TrieMap<Principal,T.Profile>(Principal.equal, Principal.hash);
       
        let now:T.Timestamp = Time.now(); // get time stamp

        //create profile
        public func createProfile( caller : Principal, profileDTO : T.CreateProfileDTO ) : T.ProfileResult {
            
            //validate data
            if(profileDTO.name.size()==0 or profileDTO.surname.size()==0){
                return #err(#InvalidData("Name or surname cannot be empty"));
            };
            
            //validate description
            switch(profileDTO.description){
                
                case(?text) if (text.size() > 1000){
                    return #err(#InvalidData("Description should not exceed 1000 characters!."));
                };

                case _ {};   
            };

            //check if userAddresses has already registered the username
            let ifUserAddressExist=profiles.get(caller);

            switch(ifUserAddressExist) {
               
                case(?ifUserAddressExist) { 
                     return #err(#AlreadyExists("User with this id already exist!."));
                 };    
                
                case(null) {
                    let saveProfile : T.Profile = {
                                        id=Principal.toText(caller);
                                        name=profileDTO.name;
                                        surname=profileDTO.surname;
                                        userAddress=profileDTO.userAddress;
                                        status=profileDTO.status;
                                        description=profileDTO.description;
                                        profileImage=profileDTO.profileImage;
                                        createdOn=now;
                                        modifiedOn=now;
                                    };
                    profiles.put(caller,saveProfile);
                     
                    return #ok;   
                };
            };   
        };


    
        public func updateProfile(caller : Principal, profileDTO : T.UpdateProfileDTO) : Result.Result<T.Profile, T.ProfileError> {
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
                        profileImage = ?Option.get(profileDTO.profileImage,Blob.fromArray([]));
                        createdOn = profile.createdOn;
                        modifiedOn=now;
                    };

                    profiles.put(caller,updatedProfile);
                    return #ok(updatedProfile);
                };
                
                case (null) {
                    return #err(#NotFound);
                };
            };

        };


        //Get Profile
        public func getProfile(caller:Principal) :  Result.Result<T.Profile,T.ProfileError>{
            let result = profiles.get(caller);
            switch(result){
                case (?profile) {
                    return #ok(profile);
                };
                case (null) {
                    return #err(#NotFound);
                };
            };
        };


        //Get Principal Id using userAddress
        public func getPrincipalId(userAddress:Text):?Principal{
            for((principal,profile) in profiles.entries()){
                if(profile.userAddress==userAddress){
                    return ?principal;
                };      
            };
            return null;

        };


        //Get Principal Id using userAddress
        public func getUserAddress(caller:Principal) : ?Text{
            let profile=profiles.get(caller);
            switch(profile){
                case(?profile) ?profile.userAddress;
                case(null) null;
            };     
        };


        //Delete Profile
        public func deleteProfile(caller:Principal) : T.ProfileResult{
            profiles.delete(caller);
            return #ok;
        };


        public func setStableProfile(stableProfile:[(Principal,T.Profile)]):(){
            
            var temp_profiles:TrieMap.TrieMap<Principal,T.Profile> = TrieMap.TrieMap<Principal,T.Profile>(Principal.equal, Principal.hash);
            
            for(profile:(Principal,T.Profile) in Iter.fromArray(stableProfile)){
                temp_profiles.put(profile.0,profile.1);
            };
            profiles:=temp_profiles;
        };


        public func getStableProfiles():[(Principal,T.Profile)]{
            return Iter.toArray(profiles.entries());
        };

    };


};

