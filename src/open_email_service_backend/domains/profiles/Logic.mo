import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import T "Types";

module{

    public class ProfileManager(){

        //hashmap <Principal, Profile>
        private var profiles:TrieMap.TrieMap<Principal,T.Profile> = TrieMap.TrieMap<Principal,T.Profile>(Principal.equal, Principal.hash);
       
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
                                    };
                    profiles.put(caller,saveProfile);
                     
                    return #ok;   
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

