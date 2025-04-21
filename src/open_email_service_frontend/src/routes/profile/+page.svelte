<script>
  import { signOut } from "$lib/services/auth.service";
  import { authSignedInStore } from "$lib/derived/auth.derived";
  import { profileStore } from "$lib/store/profile-store";

  if (!authSignedInStore) {
    signOut();
  }

  let name = '';
  let surname = '';
  let userAddress = '';
  let status = ''; 
  let description = ''; 

  async function handleSubmit() {
    const profileData = {
      name,
      surname,
      userAddress,
      status,
      description
    };

    const testData = await profileStore.createProfile(profileData);
    console.log(testData,"data after profile creation")
    name='';
    surname = '';
    userAddress = '';
    status = ''; 
    description = ''; 
  }
</script>

<div class="max-w-3xl mx-auto p-6 bg-white shadow-lg rounded-lg mt-10">
<h1 class="text-2xl font-semibold mb-6 text-center">Create Profile</h1>

<form on:submit|preventDefault={handleSubmit} class="space-y-6">

  <div>
    <label for="name" class="block text-sm font-medium mb-1">First Name</label>
    <input
      id="name"
      type="text"
      bind:value={name}
      class="w-full border px-3 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-300"
    />
  </div>

  <div>
    <label for="surname" class="block text-sm font-medium mb-1">Last Name</label>
    <input
      id="surname"
      type="text"
      bind:value={surname}
      class="w-full border px-3 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-300"
    />
  </div>

  <div>
    <label for="address" class="block text-sm font-medium mb-1">Address</label>
    <input
      id="address"
      type="text"
      bind:value={userAddress}
      class="w-full border px-3 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-300"
    />
  </div>

  <div>
    <label for="status" class="block text-sm font-medium mb-1">Status</label>
    <input
      id="status"
      type="text"
      bind:value={status}
      class="w-full border px-3 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-300"
      placeholder="Enter your status"
    />
  </div>

  <div>
    <label for="description" class="block text-sm font-medium mb-1">Description</label>
    <textarea
      id="description"
      rows="3"
      bind:value={description}
      class="w-full border px-3 py-2 rounded-md focus:outline-none focus:ring focus:border-blue-300"
      placeholder="Enter a brief description"
    ></textarea>
  </div>

  <div class="text-center">
    <button type="submit" class="bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700 transition">
      Save Profile
    </button>
  </div>

</form>
</div>
