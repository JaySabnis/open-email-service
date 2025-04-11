import Principal "mo:base/Principal";
import Result "mo:base/Result";
import ProfileLogic "domains/profiles/Logic";
import ProfileType "domains/profiles/Types";

actor {


  stable var stable_profile:[(Principal,ProfileType.Profile)] = [];

  let profileService=ProfileLogic.Service();

  //update or create profile
  public shared ({caller}) func setProfile(name:Text, surname:Text, description:?Text):async ProfileType.ProfileResult{

     let profile ={
            id=Principal.toText(caller);
            name=name;
            surname;
            description;
      };

    profileService.setProfile(caller,profile);
  };

  // return result should be in main
  public shared({caller}) func getProfile():async Result.Result<ProfileType.Profile,ProfileType.ProfileError>{
    profileService.getProfile(caller);
  };

  system func preupgrade(){
    // stable_profile:=profileService.getStableProfiles(); always set it to empty.
  };

  system func postupgrade(){
    // profileService.setStableProfile(stable_profile);
  };


};
