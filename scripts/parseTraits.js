function parsePools() {

    const traitPools = require("./values/Trait_Pools.json");

    let resultObject = {};

    const propertyIndexes = Object.keys(traitPools);

    for (let i = 0; i < propertyIndexes.length; i++) {

        let propertyIndex = propertyIndexes[i];

        propertyIndex = parseInt(propertyIndex);

        let propertyRarities = [];

        let propertyTraits = [];

        let propertyThresholds = []

        const propertyPools = traitPools[propertyIndex]

        const poolIndexes = Object.keys(propertyPools);

        for(let j = 0; j < poolIndexes.length; j++) {

            const poolIndex = poolIndexes[j];

            const pool = propertyPools[poolIndex];

            propertyRarities.push(pool.Rarity)

            propertyTraits.push(pool.Trait_Num);
        
            propertyThresholds.push(pool.Pool_Threshold);
            
        }

        resultObject[propertyIndex] = {"rarities" : propertyRarities, "traits" : propertyTraits, "thresholds" : propertyThresholds };

    }

    return resultObject;


}

async function setPools(metadataContract, collectionId) {

    const poolObject = parsePools();

    const propertyIndexes = Object.keys(poolObject);

    for (let i = 0; i < propertyIndexes.length; i++) {
        const propertyIndex = propertyIndexes[i];

        const pools = poolObject[propertyIndex];

        const traits = pools["traits"];

        let rarities = pools["rarities"];

        for(let i = 0; i < traits.length; i++) {

            const t = traits[i];

            let r = rarities[i];

            if(r.length == 0) {

                const raritiesEach = 200 / t.length;

                rarities[i] = []
    
                for(let j = 0; j < t.length; j++) {

                    rarities[i].push(Math.floor(raritiesEach));
    
                }

            }

        }

        const thresholds = pools["thresholds"];

        await metadataContract.initialize_attributes(propertyIndex, traits, rarities, thresholds, collectionId);

    }


}

async function setTraitNames(metadataContract, collectionId) {

    let traitNames = await require("./values/Trait_Names.json");

    for(propertyIndex in traitNames) {

        const property = traitNames[propertyIndex];

        let names = property["Trait_Names"];

        let propertyName = property["Attribute_Name"];

        if(propertyName == "Background") {
            console.log(names);
            console.log(propertyIndex);
        }

        let traitNums = property["Trait_Nums"];

        await metadataContract.initializeTraitNames(names, traitNums, propertyName, propertyIndex, collectionId)
    }

}

module.exports = { setTraitNames, setPools }