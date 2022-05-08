import { SubscriptionOperation } from "@urql/core/dist/types/exchanges/subscription";
import { Channel, Socket } from "phoenix";
import { make, pipe, toObservable } from "wonka";

const WS_URL = process.env.VUE_APP_WS_URL;

const socket = new Socket(`${WS_URL}/socket`, {});
socket.connect();
const absintheChannel = socket.channel("__absinthe__:control");
absintheChannel.join();

export const absintheConfig = {
  forwardSubscription(operation: SubscriptionOperation) {
    let subscriptionChannel: Channel;

    const source = make((observer) => {
      const { next } = observer;

      absintheChannel.push("doc", operation).receive("ok", (v) => {
        const subscriptionId = v.subscriptionId;

        if (subscriptionId) {
          subscriptionChannel = socket.channel(subscriptionId);
          subscriptionChannel.on("subscription:data", (value) => {
            next(value.result);
          });
        }
      });

      return () => {
        subscriptionChannel?.leave();
      };
    });

    return pipe(source, toObservable);
  },
};
