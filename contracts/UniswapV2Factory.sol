pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

// The factory holds the generic bytecode responsible for powering pairs. Its primary job is to create one and only one smart contract per unique token pair. It also contains logic to turn on the protocol charge.
// 为每一对代币产生唯一一个智能合约
contract UniswapV2Factory is IUniswapV2Factory {
    // 协议手续费 0.05%,可以打开可以关闭.初始时，feeTo没有被设定，不收手续费 Liquidity provider fees (设置流动性提供者需要付出的手续费)
    // In the future, it is possible that a protocol-wide charge of 0.05% per trade will take effect. This represents ⅙th (16.6̅%) of the 0.30% fee. The fee is in effect if feeTo is not address(0) (0x0000000000000000000000000000000000000000), indicating that feeTo is the recipient of the charge.
    address public feeTo;
    // 可以设置协议手续费的地址
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    // 设置合约创建者
    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    // 获取所有交易对的数量
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    // 产生代币对的合约
    // 通过排序保证token0小于token1
    // 最终创建的合约对第一对为1，第二对顺序为2,由此类推
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // 初始化交易对
        IUniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
