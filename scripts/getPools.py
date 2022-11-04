from xml.dom.minidom import Attr
import pandas
import numpy
from collections import OrderedDict
import sys
import os
import json


def mk_df_names(pools):
    
    """
    THIS FUNCTION WILL TAKE THE TRAITPOOLS DATAFRAME AND RETURN:
    
    name_dict --> DICTIONARY MAPPING ATTRIBUTE NUMBER TO DICTIONARY OF:
        1) IT'S NAME
        2) TRAIT_NAMES ARRAY
        3) TRAIT_NUMS ARRAY
    
    df_names --> DATAFRAME OF ALL UNIQUE TRAITS AND THEIR ID NUMBERS AS WELL AS THEIR CORRESPONDING ATTRIBUTE 

    """

    attributes = pools['Attribute'].unique()
    
    #THESE ARRAYS WILL BECOME COLUMNS OF DF_NAMES
    trait_nums=[]
    trait_names=[]
    attribute_col=[]
    
    # AS WE LOOP THROUGH SUB-DATAFRAMES FOR EACH ATTRIBUTE WE WILL USE START NUM TO 
    # KEEP TRACK OF THE STARTING INDEX FOR EACH ATTRIBUTE'S TRAITS BASED OF THE LAST ATTRIBUTE'S
    # LARGEST TRAIT INDEX 

    start_num=0
    
    
    name_dict=OrderedDict({})

    # LOOP THROUGH EACH ATTRIBUTE TO CREATE DICTIONARY FOR IT'S TRAITS AND THEIR ID'S (name_dict)
    # THEN APPEND THESE TO THEIR CORRESPONDING ARRAYS TO CREATE THE DF OF TRAIT_NAMES (df_names)
    for i in list(range(0, len(attributes))):
        attr_df=pools[pools['Attribute']==attributes[i]]

        
        nums=numpy.arange(start_num, start_num+len((attr_df['Trait'].unique()))).astype(int)
        names=attr_df['Trait'].unique()


        
        name_dict[i]=OrderedDict({'Attribute_Name':attributes[i],
                            'Trait_Nums':nums.tolist(), 
                            'Trait_Names':names.tolist()
                    })

        trait_nums= numpy.append(trait_nums, nums)
        trait_names= numpy.append(trait_names, names)
        attribute_col=numpy.append(attribute_col, ([attributes[i]]*len(nums)))
     

        # SET START_NUM TO LENGTH OF TRAITS FOR THE STARTING INDEX OF THE NEXT ATTRIBUTE :) 
        start_num=trait_nums[len(trait_nums)-1]+1
    

    print(len(attribute_col))
    print(len(trait_names))
    print(len(trait_nums))

    df_names = pandas.DataFrame({'Attribute':attribute_col, 
                                'Trait_Name':trait_names,  
                                'Trait_Num':trait_nums})

    return df_names, name_dict

def mk_traitPool(pool, df, attr_traitnames, attr):
    """
    TAKE TRAITS FOR A GIVEN POOL AND RETURN A DICT OF:
        1)TRAIT NUMBER ARRAY
        2)RARITY ARRAY
        3)POOL THRESHOLD 

    """

    #DATAFRAME FOR A GIVEN POOL OF A GIVEN ATTRIBUTE
    pool_df=df[df['Pool']==pool]
    # pool_traitnames= attr_traitnames[attr_traitnames['Pool']==pool]
    pool_df["Trait_Num"]=pool_df["Trait"].map(attr_traitnames.set_index( "Trait_Name")["Trait_Num"])

    # print("Pool:"+str(pool))
    # print(pool_df['Trait_Num'])
    # print(pool_df['Trait'])
    
    out_dict=OrderedDict({})

    out_dict['Trait_Num']=list(pool_df['Trait_Num'].values.astype(int))
    out_dict['Rarity']=list(pool_df['Rarity'].values)
    out_dict['Pool_Threshold']=int(pool_df['Pool_Thresh'].unique()[0])
    
    rarity_sum=sum(list(pool_df['Rarity'].values))
    if(rarity_sum != 100):
        print("\n********************************************************")
        print("\nError: Rarities for Attribute:%s Pool:%s do not sum to 100"%(attr, str(pool)))
        print("Instead, the rarities sum to: %s"%(str(rarity_sum)))
        print("Please adjust in the Trait_Pools.csv file, and kindly go fuck yourself :)\n")
        print("********************************************************\n")
        sys.exit()

    return out_dict

def mk_attr_dict(attr, df, df_traitnames):
    """
    TAKE ATTRIBUTE INDEX AND POOL DF AND MAKE THE DICTIONARY OF TRAIT POOLS FOR A GIVEN ATTRIBUTE

    """
    attr_pools= df[df['Attribute']==attr]
    attr_traitnames=df_traitnames[df_traitnames['Attribute']==attr]
    pool_dict=OrderedDict({})
    for pool in attr_pools['Pool'].unique():
        traitPool=mk_traitPool(pool, attr_pools, attr_traitnames, attr)
        pool_dict[int(pool)]= traitPool
    
    return pool_dict

def mk_pool_dict(df_pools, df_attributes, df_traitnames):
    """
    THIS FUNCTION TAKES TRAIT POOLS DF (df_pools) AND ATTRIBUTES DF (df_attributes) 
    TO CREATE A DICTIONARY (out_dict) COMPRISED OF:
        1) Attribute number --> dictionary of all trait pools for a given attribute 

    """
    
    Attributes = df_attributes["Attribute"].values
    out_dict=OrderedDict({})

    for i in range(0,len(Attributes)):
        attribute_dict = mk_attr_dict(Attributes[i], df_pools, df_traitnames)
        out_dict[int(i)]=attribute_dict
    
    return out_dict
    
def main():
    out_directory=os.path.join("scripts", "values")
    pool_file_name=os.path.join(out_directory, "Trait_pools.csv")
    attr_file_name=os.path.join(out_directory, "Attributes.csv")

    df_pools = pandas.read_csv(pool_file_name)
    # df_pools.fillna('No_Trait', inplace=True)
    # df_pools.to_csv(pool_file_name)
    # sys.exit()

    df_attributes = pandas.read_csv(attr_file_name)

    df_traitnames, name_dict = mk_df_names(df_pools)

    df_traitnames_file=os.path.join(out_directory, 'Trait_Names.csv')
    df_traitnames.to_csv(df_traitnames_file, index=False)

    
    trait_names_json_filename= os.path.join(out_directory,"Trait_Names.json")

    with open(trait_names_json_filename, 'w') as fp:
        json.dump(name_dict, fp)

    fp.close()

    # MAP OUR TRAIT ID NUMBERS TO THEIR TRAITNAMES IN THE TRAIT POOLS DF
    df_traitnames['Trait_Num']= df_traitnames['Trait_Num'].astype(int)
    
    # df_pools["Trait_Num"]=df_pools["Trait"].map(df_traitnames.set_index("Attribute", "Trait_Name")["Trait_Num"])
    # print(df_traitnames['Trait_Num'])
    # print(df_pools['Trait_Num'])
    # sys.exit()



    pool_dict = mk_pool_dict(df_pools, df_attributes, df_traitnames)
    
    

    trait_pools_json_filename= os.path.join(out_directory,"Trait_Pools.json")

    class NpEncoder(json.JSONEncoder):
        def default(self, obj):
            if isinstance(obj, numpy.integer):
                return int(obj)
            if isinstance(obj, numpy.floating):
                return float(obj)
            if isinstance(obj, numpy.ndarray):
                return obj.tolist()
            return super(NpEncoder, self).default(obj)


    with open(trait_pools_json_filename, 'w') as fp:
        json.dump(pool_dict, fp, cls=NpEncoder)

    fp.close()


if __name__=="__main__":

    main()