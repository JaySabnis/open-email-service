import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Bool "mo:base/Bool";

import ProfileLogic "domains/profiles/Logic";
import ProfileType "domains/profiles/Types";

import EmailTypes "domains/emails/EmailTypes";
import EmailManager "domains/emails/EmailLogic";


actor {

  stable var stable_profile:[(Principal,ProfileType.Profile)] = [];
  stable var stable_emailStore:[(Text,EmailTypes.Email)] = [];
  stable var stable_registries:[(Principal,EmailTypes.EmailRegistry)] = [];
  //todo: stable user address stores.

  //profile manager
  let profileService=ProfileLogic.ProfileManager();
  
  //Email Manager
  let emailManager= EmailManager.EmailManager();

  //create profile
  public shared ({caller}) func createProfile(profile:ProfileType.CreateProfileDTO):async ProfileType.ProfileResult{
    profileService.createProfile(caller,profile);
  };

  //check if user address is available 
  public query func isUserAddressAvailable(userAddress:Text):async Bool{
    return profileService.isUserAddressAvailable(userAddress);
  };

  //update  profile
  public shared ({caller}) func updateProfile(profile:ProfileType.UpdateProfileDTO):async Result.Result<ProfileType.Profile,ProfileType.ProfileError>{
    profileService.updateProfile(caller,profile);
  };

  // return result should be in main
  public shared({caller}) func getProfile(): async Result.Result<ProfileType.Profile,ProfileType.ProfileError>{
    profileService.getProfile(caller);
  };

  //delete profile
  public shared({caller}) func deleteProfile() : async ProfileType.ProfileResult{
    emailManager.deleteMails(caller);
    profileService.deleteProfile(caller); 
  };


  public shared ({caller}) func sendEmail(mail:EmailTypes.SendEmailDTO): async Result.Result<EmailTypes.Email,EmailTypes.EmailErrors>{
   
    let senderAddress:?Text=profileService.getUserAddress(caller);
    let recipientPrinicpalId:?Principal=profileService.getPrincipalId(mail.to);
    
    //todo always ensure data here , and not in manager.
    await emailManager.sendEmail(senderAddress,caller,recipientPrinicpalId,mail);
  };


  public shared({caller}) func markItAsImportant(emailId:Text): async () {
    emailManager.markItAsImportant(caller,emailId); 
  };


  public shared({caller}) func getMailById(mailId:Text): async Result.Result<EmailTypes.EmailBodyResponseDTO,EmailTypes.EmailErrors>{
    return emailManager.getMailById(caller,mailId);
  };


  public shared({caller}) func fetchInboxMails(pageNumber:Nat,pageSize:Nat): async [EmailTypes.EmailResponseDTO] {
    await  emailManager.fetchInboxMails(caller,pageNumber,pageSize);
  };


  public shared({caller}) func fetchOutboxMails(pageNumber:Nat,pageSize:Nat): async [EmailTypes.EmailResponseDTO]{
    await  emailManager.fetchOutboxMails(caller,pageNumber,pageSize);
  };


  system func preupgrade(){
    stable_profile:=profileService.getStableProfiles(); 
    stable_emailStore:=emailManager.getStableEmailStore();
    stable_registries:=emailManager.getStableRegistries();
  };

  system func postupgrade(){
    profileService.setStableProfile(stable_profile);
    emailManager.setStableEmailStore(stable_emailStore);
    emailManager.setStableRegistries(stable_registries);
  };


};
