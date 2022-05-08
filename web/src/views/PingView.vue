<template>
  <div>
    <h1>pong</h1>
    <div v-if="fetching">Loading...</div>
    <div v-else-if="error">Oh no... {{ error }}</div>
    <div v-else>
      <div v-if="data">{{ data.ping.status }}</div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { usePingQuery } from "@/generated/graphql.ts";

const { fetching, error, data } = usePingQuery();
</script>
