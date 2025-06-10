import Text "mo:base/Text";
import Random "mo:base/Random";
import Iter "mo:base/Iter";
import Char "mo:base/Char";
import UUID "mo:idempotency-keys/idempotency-keys";

module {

    public class Utlis() {

        public func generateUUID() : async Text {
            let entropy = await Random.blob();
            let idempotentKey : Text = UUID.generateV4(entropy);
            return idempotentKey;
        };

        public func subText(value : Text, indexStart : Nat, indexEnd : Nat) : Text {
            if (indexStart == 0 and indexEnd >= value.size()) {
                return value;
            } else if (indexStart >= value.size()) {
                return "";
            };

            var indexEndValid = indexEnd;
            if (indexEnd > value.size()) {
                indexEndValid := value.size();
            };

            var result : Text = "";
            var iter = Iter.toArray<Char>(Text.toIter(value));
            for (index in Iter.range(indexStart, indexEndValid - 1)) {
                result := result # Char.toText(iter[index]);
            };

            result;
        };
    }

};
