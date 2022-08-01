/* global ethers */
/* eslint prefer-const: "off" */

const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function deployDiamond () {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  // deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
  const diamondCutFacet = await DiamondCutFacet.deploy()
  await diamondCutFacet.deployed()
  console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

  // deploy Diamond
  const Diamond = await ethers.getContractFactory('Diamond')
  const diamond = await Diamond.deploy(contractOwner.address, diamondCutFacet.address)
  await diamond.deployed()
  let diamondAddress = diamond.address
  console.log('Diamond deployed:', diamond.address)

  // deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  // TODO
  const DiamondInit = await ethers.getContractFactory('DiamondInit')
  // const DiamondInit = await ethers.getContractFactory('ERC721Init')
  const diamondInit = await DiamondInit.deploy()
  await diamondInit.deployed()
  console.log('DiamondInit deployed:', diamondInit.address)

  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'DiamondLoupeFacet',
    'OwnershipFacet',
    'AccessControlFacet',
    // 'ERC721URIStorage',
    
    'ERC721Facet'
    // 'ERC721URIStorage'
  ]
  const cut = []
  const contractAddresses = []
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.deployed()
    console.log(`${FacetName} deployed: ${facet.address}`)
    
    contractAddresses.push(facet.address)
    
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(FacetName, facet)
    })
  }

  // upgrade diamond with facets
  console.log('')
  console.log('Diamond Cut:', cut)
  const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
  let tx
  let receipt
  // call to init function
  let args = {name: "Catas", symbol: "CATAS", supply: 500}
  let functionCall = diamondInit.interface.encodeFunctionData('init', [args])
  
  tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
  console.log('Diamond cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  console.log('Completed diamond cut')
  
  
  
  // console.log('Test function in diamond');
  
  const ERC721Diamond = await ethers.getContractAt(
    "ERC721Facet",
    diamond.address
  );
  
  // console.log(ERC721Diamond)
  // console.log(ERC721Diamond.address)
  
  // let owner = await ERC721Diamond.owner();
  // console.log(`owner is ${owner}`)
  
  // let erc721Symbol = await ERC721Diamond.symbol();
  // let erc721Name = await ERC721Diamond.name(diamond.address);
  // let erc721MaxSupply = await ERC721Diamond.maxSupply();
  //
  //
  // console.log(`Name is ${erc721Name}`);
  // console.log(`Symb is ${erc721Symbol}`);
  // console.log(`asdf is ${erc721MaxSupply}`)
  
  
  return diamond.address
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDiamond = deployDiamond
