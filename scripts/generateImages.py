#!/usr/bin/env python
# coding: utf-8

import json
import math
import os
import random
import time
# Import required libraries
from fileinput import filename

import numpy as np
import pandas as pd
from PIL import Image, ImageOps

numAttributes = 10

directoryName = "CatGenerations/jsonFiles/"

fileName = "handedness_aug_23_Jordan.json"

from CONFIG import CONFIG

import warnings

warnings.simplefilter(action='ignore', category=FutureWarning)

noHandClothesPath = "CLOTHES-NO-HAND"

attributeFolder = "Attributes"

doesFlip = {"Clothes" : True, "Hand" : True, "Head" : True, "Headgear" : True, "Eyes": True, "Mouth" : True, "Eyewear" : True}

caresAboutFur = {"Clothes" : True, "Hand" : True, "Head" : True, "Headgear" : True, "Tail" : True}


def parse_files(edition):

    # Define output path to output/edition {edition_num}
    op_path = os.path.join('output', 'edition ' + str(edition), 'images')

    # Create output directory if it doesn't exist
    if not os.path.exists(op_path):
        os.makedirs(op_path)

    data = json.load(open(directoryName + fileName, 'r'))

    # Input traits must be placed in the assets folder. Change this value if you want to name it something else.
    index = 0
    # Loop through all layers defined in CONFIG
    for idx in data:

        fur = "Grey"

        rightHanded = False

        token = data[idx]

        tokenObject = {}

        hasHand = True

        tokenName = token["name"]

        toFlip = {}

        if(len(tokenName.split("The Late")) > 1):

            continue

        attributes = token["attributes"]

        for attribute in attributes:

            propertyName = attribute['trait_type']

            trait = attribute['value']

            if(propertyName == "Fur"):

                fur = trait

        furPath = fur + "/"


        for attribute in attributes:

            propertyName = attribute['trait_type']

            trait = attribute['value']

            if(propertyName == "Fur"):
                continue

            if (propertyName == "Handedness"):

                if(trait == "Right"):

                    rightHanded = True

                    continue

            #trait = trait.replace(" ", "_")

            if(propertyName in caresAboutFur):

                path =  propertyName.upper() + "/" + furPath + trait

            else:
                path = propertyName.upper() + "/" + trait

            if(propertyName == "Hand"):

                if(trait == "No_Trait"):

                    hasHand = False


            if trait == "No_Trait":

                continue

            if(propertyName in doesFlip):

                toFlip[path + ".png"] = True

            print(path)
              
            tokenObject[propertyName] = path + ".png"

        clothesPath = "CLOTHES-NO-HAND/"
        
        if hasHand:

            clothesPath = "CLOTHES-HAND/"

        print(tokenObject["Clothes"])


        tokenObject["Clothes"] = clothesPath + furPath + tokenObject["Clothes"].split("/")[2]
        toFlip[clothesPath + furPath + tokenObject["Clothes"].split("/")[2]] = True

        imagePaths = []

        for i in range(numAttributes):

            ele = CONFIG[i]

            name = ele["name"]

            if name in tokenObject:

                imagePaths.append(tokenObject[name])

        
        # Generate the actual image
        generate_single_image(imagePaths, os.path.join(op_path, str(index) + ".png"), toFlip, rightHanded)
        index += 1



# Parse the configuration file and make sure it's valid
def parse_config():
    
    # Input traits must be placed in the assets folder. Change this value if you want to name it something else.
    index = 0
    # Loop through all layers defined in CONFIG
    for layer in data:

        index += 1

        # Go into assets/ to look for layer folders
        layer_path = os.path.join(assets_path, layer['directory'])
        
        # Get trait array in sorted order
        traits = sorted([trait for trait in os.listdir(layer_path)if trait[0] != '.'])

        # If layer is not required, add a None to the start of the traits array
        if not layer['required']:
            traits = [None] + traits
        
        # Generate final rarity weights
        if layer['rarity_weights'] is None:
            rarities = [1 for x in traits]
        elif layer['rarity_weights'] == 'random':
            rarities = [random.random() for x in traits]
        elif type(layer['rarity_weights'] == 'list'):

            weights = layer['rarity_weights']

            if len(weights) == 1 and not layer['required']:

                toAdd = 1000 - weights[0]

                amountEach = math.floor(toAdd / len(traits))

                rarities = [weights[0]]

                for i in range(len(traits) - 1):

                    rarities.append(amountEach)

            else:
            
                assert len(traits) == len(layer['rarity_weights']), "Make sure you have the current number of rarity weights"


                rarities = layer['rarity_weights']
        else:
            raise ValueError("Rarity weights is invalid")
        
        rarities = get_weighted_rarities(rarities)

        assert(len(traits) == len(rarities))
        
        # Re-assign final values to main CONFIG
        layer['rarity_weights'] = rarities

        sum = np.cumsum(rarities)
        assert(len(sum) == len(traits))
        layer['cum_rarity_weights'] = sum
        layer['traits'] = traits

# Parse the configuration file and make sure it's valid
def parse_config_2():
    
    # Input traits must be placed in the assets folder. Change this value if you want to name it something else.
    index = 0
    # Loop through all layers defined in CONFIG
    for layer in CONFIG:

        index += 1

        #layer_path = os.path.join(directoryPath, layer['directory']) + ".xlrd"

        xlsx_layer_path = xlsxPath + layer['directory'] + ".xlsx"
        csv_layer_path = csvPath + layer['directory'] + ".csv"

        data_xls = pd.read_excel(xlsx_layer_path)
        data_xls.to_csv(csv_layer_path, encoding='utf-8', index=False)

        data = pd.read_csv(csv_layer_path)

        index = 0

        traits = []
        rarities = []

        for d in data["name"]:

            try:

                if(pd.isnull(d)):

                    if(index == 0):
                       d = None
                    else:
                        break

                traits.append(d)
                rarities.append(data["value"][index])

            except:

                break

            index+=1

        # # Go into assets/ to look for layer folders
        layer_path = os.path.join(assets_path, layer['directory'])

        rarities = get_weighted_rarities(rarities)

        assert(len(traits) == len(rarities))

        # Re-assign final values to main CONFIG
        layer['rarity_weights'] = rarities

        sum = np.cumsum(rarities)
        assert(len(sum) == len(traits))
        layer['cum_rarity_weights'] = sum
        layer['traits'] = traits
        
   


# Weight rarities and return a numpy array that sums up to 1
def get_weighted_rarities(arr):
    return np.array(arr)/ sum(arr)

# Generate a single image given an array of filepaths representing layers
def generate_single_image(filepaths, output_filename, toFlip, rightHanded):
    
    # Treat the first layer as the background
    bg = Image.open(os.path.join(attributeFolder, filepaths[0]))

    bg = bg.convert('RGBA')

    final = Image.new("RGBA", bg.size)

    final = Image.alpha_composite(final, bg)
    
    # Loop through layers 1 to n and stack them on top of another
    for filepath in filepaths[1:]:
        if filepath.endswith('.png'):

            img = Image.open(os.path.join(attributeFolder, filepath))
            img = img.convert('RGBA')

            if(rightHanded):

                if(filepath in toFlip):
                    img = ImageOps.mirror(img)

            final = Image.alpha_composite(final, img)

    
    # Save the final image into desired location
    if output_filename is not None:
        final.save(output_filename)
    else:
        # If output filename is not specified, use timestamp to name the image and save it in output/single_images
        if not os.path.exists(os.path.join('output', 'single_images')):
            os.makedirs(os.path.join('output', 'single_images'))
        final.save(os.path.join('output', 'single_images', str(int(time.time())) + '.png'))



# Get total number of distinct possible combinations
def get_total_combinations():
    
    total = 1
    for layer in CONFIG:
        total = total * len(layer['traits'])
    return total


# Select an index based on rarity weights
def select_index(cum_rarities, rand):
    
    cum_rarities = list(cum_rarities)

    if cum_rarities[len(cum_rarities) - 1] > 1:
        cum_rarities[len(cum_rarities) - 1] = 1
    for i in range(len(cum_rarities)):
        if rand <= cum_rarities[i]:
            return i
    
    # Should not reach here if everything works okay
    return None


# Generate a set of traits given rarities
def generate_trait_set_from_config(imageNum):
    
    trait_set = []
    trait_paths = []

    rareEyes = ""

    maskType = ""

    glassesType = ""

    eyeBrows = ""

    traits = []

    for layer in CONFIG:
        # Extract list of traits and cumulative rarity weights
        traitList, cum_rarities = layer['traits'], layer['cum_rarity_weights']

        assert(len(traitList) == len(cum_rarities))

        # Generate a random number
        rand_num = random.random()


        index = select_index(cum_rarities, rand_num)

        # Select an element index based on random number and cumulative rarity weights
        traits.append(traitList[index])

    index = 0

    isHand = True


    #set restrictions based on if traits are present
    for layer in CONFIG:

        trait = traits[index]

        name = layer["name"]

        if(name == "Hand"):

            if(trait == None):
                isHand = False

            
        index += 1

    index = 0


    for layer in CONFIG:

        trait = traits[index]

        name = layer["name"]

        addTrait = True
        addPath = True

        traitAdded = False

        # Add trait path to trait paths if the trait has been selected
        if trait is not None:




            trait_path = os.path.join(layer['directory'], trait)

            if(name == "Clothes" and not isHand):

                trait_path = os.path.join(noHandClothesPath, trait)
        

            if addTrait:
                # Add selected trait to trait set
                trait_set.append(trait)
                traitAdded = True
            if addPath:
                trait_paths.append(trait_path)

        if(not traitAdded):

            trait_set.append(None)

        index += 1
        
    return trait_set, trait_paths


# Generate the image set. Don't change drop_dup
def generate_images(edition, count, drop_dup=False):
    
    # Initialize an empty rarity table
    rarity_table = {}
    for layer in CONFIG:
        rarity_table[layer['name']] = []

    # Define output path to output/edition {edition_num}
    op_path = os.path.join('output', 'edition ' + str(edition), 'images')

    # Will require this to name final images as 000, 001,...
    zfill_count = len(str(count - 1))
    
    # Create output directory if it doesn't exist
    if not os.path.exists(op_path):
        os.makedirs(op_path)
      
    # Create the images
    for n in range(count):
        
        # Set image name
        image_name = str(n) + '.png'
        
        # Get a random set of valid traits based on rarity weights
        trait_sets, trait_paths = generate_trait_set_from_config(n)

        # Generate the actual image
        generate_single_image(trait_paths, os.path.join(op_path, image_name))
        
        # Populate the rarity table with metadata of newly created image
        for idx, trait in enumerate(trait_sets):

          
            if trait is not None:

                traitName = trait[: -1 * len('.png')]

                traitWords = traitName.split("_")

                t = ""

                i = 0

                for name in traitWords:

                    if name.isnumeric():

                        continue

                    t += name

                    if i < len(traitWords) - 1:

                        t += " "

                    i+=1

                t = t.capitalize()

                rarity_table[CONFIG[idx]['name']].append(t)

            else:
                rarity_table[CONFIG[idx]['name']].append('none')

    #print(rarity_table)
    
    # Create the final rarity table by removing duplicate creat
    rarity_table = pd.DataFrame(rarity_table).drop_duplicates()
    print("Generated %i images, %i are distinct" % (count, rarity_table.shape[0]))

     # Define output path to output/edition {edition_num}
    final_op_path = os.path.join('output', 'final edition ' + str(edition), 'images')
    
    if drop_dup:
        # Get list of duplicate images
        img_tb_removed = sorted(list(set(range(count)) - set(rarity_table.index)))

        # Remove duplicate images
        print("Removing %i images..." % (len(img_tb_removed)))

        toRemove = []

        #op_path = os.path.join('output', 'edition ' + str(edition))
        for i in img_tb_removed:
            print(i)
            os.remove(os.path.join(op_path, str(i) + '.png'))
            toRemove.append(i)


        count = 0

        listDirectory = os.listdir(op_path)

        numList = []

        for ele in listDirectory:

            split = ele.split(".")

            numList.append(int(split[0]))

        # Rename images such that it is sequentialluy numbered
        for idx, img in enumerate(sorted(numList)):

            
            os.rename(os.path.join(op_path, str(img) + '.png'), os.path.join(op_path, str(idx) + '.png'))
            
        
    
    # Modify rarity table to reflect removals
    rarity_table = rarity_table.reset_index()
    rarity_table = rarity_table.drop('index', axis=1)
    return rarity_table

def renameFiles():

    # # Loop through all layers defined in CONFIG
    for layer in CONFIG:

        # Go into assets/ to look for layer folders
        layer_path = os.path.join(attributeFolder, layer["directory"])

        listDirectory = os.listdir(layer_path)

            # Rename images such that it is sequentialluy numbered
        for idx, img in enumerate(sorted(listDirectory)):

            #newName = img.split(" #")[0]
            newNameList = img.split(".png.png")

            if len(newNameList) > 1:

                os.rename(os.path.join(layer_path, str(img)), os.path.join(layer_path, str(newNameList[0]) + ".png"))


def renameSkinFiles():

   

    # Go into assets/ to look for layer folders
    layer_path = os.path.join('SKIN', "SKIN 1")

    listDirectory = os.listdir(layer_path)

    listOfNames = []

    # Rename images such that it is sequentialluy numbered
    for idx, img in enumerate(sorted(listDirectory)):

        name = str(img)

        name = name.split("_")[1]

        listOfNames.append(name)

        os.rename(os.path.join(layer_path, str(img)), os.path.join(layer_path, name))

      # Go into assets/ to look for layer folders
    layer_path = os.path.join('SKIN', "SKIN 2")

    listDirectory = os.listdir(layer_path)

    index = 0
    # Rename images such that it is sequentialluy numbered
    for idx, img in enumerate(sorted(listDirectory)):


        name = listOfNames[index]

        os.rename(os.path.join(layer_path, str(img)), os.path.join(layer_path, name))

        index += 1

       # Go into assets/ to look for layer folders
    layer_path = os.path.join('SKIN', "SKIN 3")

    listDirectory = os.listdir(layer_path)

    index = 0
    # Rename images such that it is sequentialluy numbered
    for idx, img in enumerate(sorted(listDirectory)):


        name = listOfNames[index]

        os.rename(os.path.join(layer_path, str(img)), os.path.join(layer_path, name))

        index += 1


# Main function. Point of entry
def main2():

    #renameFiles()

    print("Checking assets...")
    parse_config()
    print("Assets look great! We are good to go!")
    print()

    tot_comb = get_total_combinations()
    print("You can create a total of %i distinct avatars" % (tot_comb))
    print()

    print("How many avatars would you like to create? Enter a number greater than 0: ")
    while True:
        num_avatars = int(input())
        if num_avatars > 0:
            break
    
    print("What would you like to call this edition?: ")
    edition_name = input()

    print("Starting task...")
    rt = generate_images(edition_name, num_avatars)

    print("Saving metadata...")
    rt.to_csv(os.path.join('output', 'edition ' + str(edition_name), 'metadata.csv'))

    print("Task complete!")

def main():

    print("What would you like to call this edition?: ")
    edition_name = input()

    parse_files(edition_name)


# Run the main function
main()
#getTotalReturns()

#parse_config_2()
