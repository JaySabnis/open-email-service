import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";

import T "Types";

module{

    public class Service(){

        //hashmap <Principal, Profile>
        var profiles:TrieMap.TrieMap<Principal,T.Profile> = TrieMap.TrieMap<Principal,T.Profile>(Principal.equal, Principal.hash);
   
        // Create or update profile

        public func setProfile( caller : Principal, profile : T.Profile ) : T.ProfileResult {
            
            //validate data
            if(profile.name.size()==0 or profile.surname.size()==0){
                return #err(#InvalidData("Name or surname cannot be empty"));
            };
            
            //validate description
            switch(profile.description){
                
                case(?text) if (text.size() > 1000){
                    return #err(#InvalidData("Description should not exceed 1000 characters!."));
                };

                case _ {};   
            };
            
            profiles.put(caller,profile);
           #ok;
        };

        //Get Profile
        public func getProfile(caller:Principal) : Result.Result<T.Profile,T.ProfileError>{
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

