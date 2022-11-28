use tyk_analytics

// work out the collection names and create them capped
db.createCollection("z_tyk_analyticz_aggregate_SBX_ORG_ID", { capped : true, size : 1048576 } )
db.createCollection("z_tyk_analyticz_SBX_ORG_ID", { capped : true, size : 1048576 } )


// another option is to find all the collections starting with z_ and cap them
//var z_Collections = db.getCollectionNames().filter(function (coll) { return coll.match(/z_/)})
//z_Collections.forEach(function(collectionName){db.runCommand( { convertToCapped: collectionName, size: 1048576 } );})
