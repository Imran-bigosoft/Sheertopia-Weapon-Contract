// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SheertopiaWeapons is ERC1155, Ownable {

    using Strings for uint256;

    struct tokenDataStruct {
        uint256 allowedAmount;
        bool unlimited;
        bool minted;
        uint256 mintedAmount;
    }

    mapping(uint256 => tokenDataStruct) private tokenData;

    uint256[] mintedTokenIdList;
    string public baseURI;

    constructor(string memory _baseURI) ERC1155(_baseURI) Ownable(msg.sender) {
        baseURI = _baseURI; 
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json")); 
    }

    function setBaseURI(string memory _newuri) public onlyOwner {
        _setURI(_newuri);
        baseURI = _newuri;
    }

    function newNftMint(
        address _account,
        uint256 _id,
        uint256 _amount,
        bytes memory _data,
        uint256 _allowedAmount,
        bool _unlimited
    ) public onlyOwner {
        require(!(_unlimited == false && _allowedAmount == 0), "_allowedAmount cannot be zero when _unlimited is false.");
        require(tokenData[_id].minted == false, "This token id is already minted");

        if (_unlimited) {
            _mint(_account, _id, _amount, _data);
        } else {
            require(_amount <= _allowedAmount, "Reduce the amount of minting NFT");
            _mint(_account, _id, _amount, _data);
        }

        tokenData[_id] = tokenDataStruct({
            allowedAmount: _allowedAmount,
            unlimited: _unlimited,
            minted: true,
            mintedAmount: _amount
        });

        mintedTokenIdList.push(_id);
    }

    function addNftAmount(
        address _account,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public onlyOwner {
        require(tokenData[_id].minted, "Nft is not Created yet, You need to Call 'newNftMint' function first");

        if (tokenData[_id].unlimited) {
            _mint(_account, _id, _amount, _data);
            tokenData[_id].mintedAmount += _amount;
        } else {
            uint256 remainingSupply = tokenData[_id].allowedAmount - tokenData[_id].mintedAmount;
            require(_amount <= remainingSupply, "Reduce the amount of minting NFT");
            _mint(_account, _id, _amount, _data);
        }
    }

    function getTokenData(uint256 _tokenId) public view returns (tokenDataStruct memory) {
        require(tokenData[_tokenId].minted, "This token is not minted yet");
        return tokenData[_tokenId];
    }

    function nftMintingAmountLeft(uint256 _tokenId) public view returns (uint256) {
        require(tokenData[_tokenId].minted, "This token is not minted yet");
        uint256 remainingSupply = tokenData[_tokenId].allowedAmount - tokenData[_tokenId].mintedAmount;
        return remainingSupply;
    }
}
