import Principal "mo:base/Principal";
import Result "mo:base/Result";
import ProfileLogic "domains/profiles/Logic";
import ProfileType "domains/profiles/Types";

actor {

  stable var stable_profile:[(Principal,ProfileType.Profile)] = [];

  let profileService=ProfileLogic.ProfileManager();

  //create profile
  public shared ({caller}) func createProfile(profile:ProfileType.CreateProfileDTO):async ProfileType.ProfileResult{
    profileService.createProfile(caller,profile);
  };

    //update  profile
  public shared ({caller}) func updateProfile(profile:ProfileType.UpdateProfileDTO):async Result.Result<ProfileType.Profile,ProfileType.ProfileError>{
    profileService.updateProfile(caller,profile);
  };

  // return result should be in main
  public shared({caller}) func getProfile(): async Result.Result<ProfileType.Profile,ProfileType.ProfileError>{
    profileService.getProfile(caller);
  };

  system func preupgrade(){
    // stable_profile:=profileService.getStableProfiles(); always set it to empty.
  };

  system func postupgrade(){
    // profileService.setStableProfile(stable_profile);
  };


};
