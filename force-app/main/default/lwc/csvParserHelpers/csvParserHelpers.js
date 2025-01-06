export const NAV_PARAMS ={ 
    1:{
        componentDomId :"c-csv-upload-and-config",
        forward:true,
        backward:false
    },
    2:{
        componentDomId :"c-csv-data-mapping",
        forward:true,
        backward:true
    },
    3:{
        componentDomId :"c-csv-mapped-data-preview",
        forward:false,
        backward:false
    }
}


export async function loadFile(file){
    return new Promise( (resolve,reject) => {
        const fileReader = new FileReader();
        fileReader.onload = () =>{
            resolve(fileReader.result);
        }
        fileReader.onerror = ()=>{
            reject(fileReader.error)
        }
        fileReader.readAsText(file);
    });

}

export function getNavParams(index){
    console.log('index :' , index)
    return NAV_PARAMS[`${index}`];
}