<template>
  <main>
    <Button @click="signIn">Google Sign in</Button>
  </main>
</template>

<script setup lang="ts">
import firebase from "@/services/firebase";
import router from "@/router";

const signIn = async () => {
  await firebase.signinWithGoogle();
  router.push({ name: "ping" });
};
</script>
