import Result "mo:base/Result";
import Text "mo:base/Text";
import Map "mo:map/Map";
import { phash; nhash} "mo:map/Map";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Principal "mo:serde/Candid/Text/Parser/Principal";
import Vector "mo:vector";

actor {
    stable var autoIndex = 0;

    stable let userIDMap = Map.new<Principal, Nat>();
    stable let userProfileMap = Map.new<Nat, Text>();
    stable let userResultsMap = Map.new<Nat, Vector.Vector<Text>>();


    public query ({ caller }) func getUserProfile() : async Result.Result<{ id : Nat; name : Text }, Text> {
        // Get user ID from userIDMap
        let userId = switch (Map.get(userIDMap, phash, caller)) {
            case (?found) found;
            case (_) return #err("User not found");
        };

        // Get user profile name from userProfileMap
        let foundName = switch (Map.get(userProfileMap, nhash, userId)) {
            case (?found) found;
            case (_) return #err("User profile not found");
        };

        return #ok({ id = userId; name = foundName });
    };

    public shared ({ caller }) func setUserProfile(name : Text) : async Result.Result<{ id : Nat; name : Text }, Text> {
        Debug.print(debug_show caller);
        // check if user already exists
        let foundUser = Map.get(userIDMap,phash,caller);

        switch (foundUser) {
            case(?_x) {}; 
            case (_) {
                // set user id
                Map.set(userIDMap, phash, caller, autoIndex);

                // increment for the next user
                autoIndex += 1;};
        };

        // set profile name
        let foundId = switch (Map.get(userIDMap, phash, caller)){
            case (?found) found; 
            case(_) return #err("User not found")
        };
        Map.set(userProfileMap, nhash, foundId, name);



        return #ok({ id = foundId; name = name });
    };

    public shared ({ caller }) func addUserResult(result : Text) : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        // check if user already exists
        let userId = switch (Map.get(userIDMap, phash, caller)) {
            case (?found) found;
            case (_) return #err("User not found");
        };

        // Get  
        let results = switch (Map.get(userResultsMap, nhash, userId)) {
            case (?found) found;
            case (_) Vector.new<Text>();
        };
        
        Vector.add(results, result);
        Map.set(userResultsMap, nhash, userId, results);

        return #ok({ id = userId; results = Vector.toArray(results) });
    };

    public query ({ caller }) func getUserResults() : async Result.Result<{ id : Nat; results : [Text] }, Text> {
            // Vérifie si l'utilisateur existe
        let userId = switch (Map.get(userIDMap, phash, caller)) {
            case (?found) found;
            case (_) return #err("User not found");
        };

    // Récupère les résultats
        let results = switch (Map.get(userResultsMap, nhash, userId)) {
            case (?found) found;
            case (_) return #err("Results not found");
        };

    // Vérifie s'il y a des résultats
        let resultSize = Vector.size(results);
        if (resultSize == 0) {
            return #err("No results available");
        };


        return #ok({ id = userId; results = Vector.toArray(results) });

    };
};