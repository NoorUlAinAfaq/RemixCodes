// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// Contract implementarion
contract MINRA is Context, IERC20, Ownable {
    

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isWhitelisted;
    address[] private _whitelisted;

    mapping(address => bool) private _blacklisted;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**4;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Minra";
    string private _symbol = "MINRA";
    uint8 private _decimals = 4;

    // Tax and charity fees will start at 0 so we don't have a big impact when deploying to Uniswap
    // Charity wallet address is null but the method to set the address is exposed
    uint256 private _taxFee = 5;
    uint256 public _liquidityFee = 5;
    uint256 public _budgetFee = 15;

    address treasuryWallet = msg.sender;
    address researchWallet = msg.sender;
    address devWallet = msg.sender;

    struct VotingProposal {
        uint256 id;
        address proposer;
        string details;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    uint256 public minLockedTokenForVoting;
    uint256 public averageHoldingAmount;
    mapping(uint256 => VotingProposal) public votingProposals;
    uint256 public proposalCounter;
    mapping(address => uint256) public userVotes;
    struct tokenHolder {
        address wallet;
        uint256 tokenBalance;
    }

  mapping(address => tokenHolder) public _tokenHoldings;
  address[] public tokenHoldersList;

    uint256 public threshold = 2000 * 10**4;

    uint256 private _previousTaxFee = _taxFee;

    // Locking periods multipliers
    uint256 public constant MULTIPLIER_30_DAYS = 1;
    uint256 public constant MULTIPLIER_60_DAYS = 25; // 2.5x
    uint256 public constant MULTIPLIER_100_DAYS = 50; // 5x

    uint256 public constant POWER_MULTIPLIER_30_DAYS = 1;
    uint256 public constant POWER_MULTIPLIER_60_DAYS = 5;
    uint256 public constant POWER_MULTIPLIER_100_DAYS = 10;

    uint256 public holderCount =  0;
    mapping(address => uint256) public lockingPeriods; // Wallets' locking periods

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 private _maxTxAmount = 100000000000000e9;
    uint256 private numTokensSellToAddToLiquidity = 500000 * 10**6 * 10**9;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    event VoteCasted(
        address voterr,
        uint256 _proposalId,
        bool _support,
        uint256 votingPower
    );

    constructor() {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        // Exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isWhitelisted[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()]  - (
                amount
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - (
                subtractedValue
            )
        );
        return true;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _isWhitelisted[account];
    }

    function setExcludeFromFee(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = excluded;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / (currentRate);
    }

    function unWhitelistAccount(address account) external onlyOwner {
        require(!_isWhitelisted[account], "Account is already whitelisted");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isWhitelisted[account] = true;
        _whitelisted.push(account);
    }

    function whitelistAccount(address account) external onlyOwner {
        require(_isWhitelisted[account], "Account is already unwhitelisted");
        for (uint256 i = 0; i < _whitelisted.length; i++) {
            if (_whitelisted[i] == account) {
                _whitelisted[i] = _whitelisted[_whitelisted.length - 1];
                _tOwned[account] = 0;
                _isWhitelisted[account] = false;
                _whitelisted.pop();
                break;
            }
        }
    }

    function removeAllFee() private {
        if (_taxFee == 0) return;

        _previousTaxFee = _taxFee;

        _taxFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (sender != owner() && recipient != owner())
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap?
        // also, don't get caught in a circular charity event.
        // also, don't swap if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            sender != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }
        uint256 budgetAmount = (amount * _budgetFee) / 1000;
        amount -= budgetAmount;
        uint256 treasuryAmount = (budgetAmount * 45) / 100;
        uint256 researchAmount = (budgetAmount * 45) / 100;
        uint256 devAmount = budgetAmount - (treasuryAmount + researchAmount);
        basicTransfer(sender, treasuryWallet, treasuryAmount);
        basicTransfer(sender, researchWallet, researchAmount);
        basicTransfer(sender, devWallet, devAmount);

        //transfer amount, it will take tax and charity fee
        _tokenTransfer(sender, recipient, amount, takeFee);
        // Update token holdings using the Member struct
    updateTokenHoldings(sender);
    updateTokenHoldings(recipient);
    tokenHoldersList.push(recipient);
    }

    function updateTokenHoldings(address account) private {
    if (_tokenHoldings[account].wallet == address(0)) {
        // If the account is not in the members mapping, add it
        _tokenHoldings[account] = tokenHolder(account, balanceOf(account));
    } else {
        // If the account is already in the members mapping, update its token balance
        _tokenHoldings[account].tokenBalance = balanceOf(account);
    }
}

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / (2);
        uint256 otherHalf = contractTokenBalance - (half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - (initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (_isWhitelisted[sender] && !_isWhitelisted[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isWhitelisted[sender] && _isWhitelisted[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isWhitelisted[sender] && !_isWhitelisted[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isWhitelisted[sender] && _isWhitelisted[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _rOwned[sender] = _rOwned[sender] - (amount);
        _rOwned[recipient] = _rOwned[recipient] + (amount);

        emit Transfer(sender, recipient, amount);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 rBurn
        ) = _getValues(tAmount);
        _rOwned[sender] -= (rAmount - rBurn);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _rOwned[address(0)] += rBurn;
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 rBurn
        ) = _getValues(tAmount);
        _rOwned[sender] -= (rAmount - rBurn);
        _rOwned[sender] = _rOwned[sender]  - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _rOwned[address(0)] += rBurn;
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * (currentRate);
        _rOwned[address(this)] = _rOwned[address(this)] + (rLiquidity);
        if (_isWhitelisted[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + (tLiquidity);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 rBurn
        ) = _getValues(tAmount);
        _rOwned[sender] -= (rAmount - rBurn);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _rOwned[address(0)] += rBurn;
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 rBurn
        ) = _getValues(tAmount);
        _rOwned[sender] -= (rAmount - rBurn);
        _tOwned[sender] = _tOwned[sender]  - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _rOwned[address(0)] += rBurn;
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - (rFee);
        _tFeeTotal = _tFeeTotal + (tFee);
    }

    // Function to lock tokens for a specific period
    function lockTokens(uint256 period) external {
        require(
            period == 30 || period == 60 || period == 100,
            "Invalid locking period"
        );
        require(balanceOf(msg.sender) >= averageHoldingAmount, "Insufficient balance");

        lockingPeriods[msg.sender] = period;
    }

    // Function to get the locking multiplier based on the locking period
    function getLockingMultiplier(address holder)
        internal
        view
        returns (uint256)
    {
        uint256 lockingPeriod = lockingPeriods[holder];
        if (lockingPeriod == 30) {
            return MULTIPLIER_30_DAYS;
        } else if (lockingPeriod == 60) {
            return MULTIPLIER_60_DAYS;
        } else if (lockingPeriod == 100) {
            return MULTIPLIER_100_DAYS;
        }
        return 0; // No multiplier for unspecified locking period
    }

     function getPowerMultiplier(address holder)
        internal
        view
        returns (uint256)
    {
        uint256 lockingPeriod = lockingPeriods[holder];
        if (lockingPeriod == 30) {
            return POWER_MULTIPLIER_30_DAYS;
        } else if (lockingPeriod == 60) {
            return POWER_MULTIPLIER_60_DAYS;
        } else if (lockingPeriod == 100) {
            return POWER_MULTIPLIER_100_DAYS;
        }
        return 0; // No multiplier for unspecified locking period
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount * (_taxFee) / (100);

        uint256 tTransferAmount = tAmount - (tFee);
        uint256 currentRate = _getRate();

        uint256 rAmount = tAmount * (currentRate);
        uint256 rFee = tFee * (currentRate);

        // // Calculate the reflection multiplier based on the locking period
        // uint256 reflectionMultiplier = getLockingMultiplier(msg.sender);

        uint256 rTransferAmount = rAmount - (rFee);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        // Calculate reflections based on the locking period multiplier
        uint256 rReflection = tFee
            * (currentRate)
            * getLockingMultiplier(msg.sender)
            / (100);

        uint256 rBurn = tFee
            * (currentRate)
            * 5
            / (100);

        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            rReflection,
            tLiquidity,
            rBurn
        );
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount * (_liquidityFee) / (10**2);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / (tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _whitelisted.length; i++) {
            if (
                _rOwned[_whitelisted[i]] > rSupply ||
                _tOwned[_whitelisted[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply - (_rOwned[_whitelisted[i]]);
            tSupply = tSupply - (_tOwned[_whitelisted[i]]);
        }
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getTaxFee() private view returns (uint256) {
        return _taxFee;
    }

    function _getMaxTxAmount() private view returns (uint256) {
        return _maxTxAmount;
    }

    function _getETHBalance() public view returns (uint256 balance) {
        return address(this).balance;
    }

    function _setTaxFee(uint256 taxFee) external onlyOwner {
        require(taxFee >= 1 && taxFee <= 10, "taxFee should be in 1 - 10");
        _taxFee = taxFee;
    }

    function _setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        
        _maxTxAmount = maxTxAmount;
    }

    function proposeVote(uint256 _proposalCounter, string memory _details, uint256 _durationInDays)
        external
        onlyOwner
    {
        uint256 endTime = block.timestamp + (_durationInDays * 1 days);
        votingProposals[_proposalCounter] = VotingProposal({
            id: _proposalCounter,
            proposer: msg.sender,
            details: _details,
            startTime: block.timestamp,
            endTime: endTime,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        proposalCounter++;
    }

    function vote(uint256 _proposalId, bool _support) external {
        // Add logic to check if the user meets the locking period requirement
        require(
            lockingPeriods[msg.sender] > 0,
            "Must have locked tokens to vote"
        );

        // Add logic to check if the user meets the minimum locked token amount for voting
        require(
            balanceOf(msg.sender) >= minLockedTokenForVoting,
            "Insufficient locked tokens for voting"
        );

        // Add logic to check if the proposal is still open for voting
        require(
            block.timestamp < votingProposals[_proposalId].endTime,
            "Voting has ended"
        );

        // Add logic to prevent users from voting multiple times on the same proposal
        require(userVotes[msg.sender] == 0, "Already voted on this proposal");

        require(!isBlackListed(msg.sender), "Voter is blacklistedd!!");

        // Update the user's voting power based on the locking period
        uint256 votingPower = getPowerMultiplier(msg.sender);

        // Update the votes for or against the proposal
        if (_support) {
            votingProposals[_proposalId].votesFor += votingPower;
        } else {
            votingProposals[_proposalId].votesAgainst += votingPower;
        }

        // Update the user's vote count and mark the user as having voted on this proposal
        userVotes[msg.sender] = _proposalId;

        // Emit an event to indicate the vote
        emit VoteCasted(msg.sender, _proposalId, _support, votingPower);
    }

    function includeInBlacklist(address wallet) external onlyOwner {
        _blacklisted[wallet] = true;
    }

    function excludeFromBlacklist(address wallet) external onlyOwner {
        _blacklisted[wallet] = false;
    }

    function isBlackListed(address wallet) public view returns (bool) {
        return _blacklisted[wallet];
    }

    function changeThreshold(uint256 amount) external onlyOwner {
        threshold = amount;
    }

    function calculateAverage() public onlyOwner {
        require(tokenHoldersList.length > 0, "Token holdings not set");

        uint256 sum = 0;
        uint256 count = 0;

        // Use a for loop to iterate through the array and calculate the sum
        //excluding the wallet holdings less than threshold and blacklisted wallets.
        for (uint256 i = 0; i < tokenHoldersList.length; i++) {
            if (!isBlackListed(tokenHoldersList[i]) && balanceOf(tokenHoldersList[i]) >= threshold){
              
                    sum += balanceOf(tokenHoldersList[i]);
                    count++;
            }
        }

        // Calculate and return the average
        averageHoldingAmount =  sum / count;
    }
}
