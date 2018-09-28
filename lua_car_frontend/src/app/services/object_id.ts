
class ObjectIdClass{
    private id : number = 0;    // Private ID counter

    public getObjectID(obj: any) : number {
        if(obj.hasOwnProperty("__objectID__")) {
            console.log("__objectID__ has:"+obj.__objectID__);
            return obj.__objectID__;
        } else {
            ++this.id;
            Object.defineProperty(obj, "__objectID__", {

                /*
                * Explicitly sets these two attribute values to false,
                * although they are false by default.
                */
                "configurable" : false,
                "enumerable" :   false,

                /* 
                * This closure guarantees that different objects
                * will not share the same id variable.
                */
                "get" : (function (__objectID__) {
                    return function () { return __objectID__; };
                })(this.id),

                "set" : function () {
                    throw new Error("Sorry, but 'obj.__objectID__' is read-only!");
                }
            });
            console.log("__objectID__ new:"+obj.__objectID__);
            return obj.__objectID__;
        }
    }
}
export const serviceObjectId : ObjectIdClass = new ObjectIdClass();