# START

Step 1: create a move project

```bash
aptos move init --name your_project_name
```

Step 2: create the Aptos private key for a specific network

```bash
aptos init --network testnet # testnet / mainnet / devnet
```
Step 3: to edit your `Move.toml` file

> Check your account address in the .aptos/config.yaml
> 
> then, add the address under the `[address]` section

for example

> The term 'create' is an alias for the account address;
> 
> you can customize it to another alias of your choice.


```toml
[addresses]
creator="0aa63268ee3a8866da86277747d8254189f5e40d9b93947ed36f27d910cc2005"
```
Step 4: create move smart contract, for example `main.move`

```move
module creator::hello {
    #[test_only]
    use std::string;
    #[test_only]
    use std::debug::print;

    #[test]
    fun test() {
        let hello = string::utf8(b"hello_world");
        print(&hello);
    }
}
```

Step 4: running test

```bash
aptos move test
```

Step 5: compile smart contract as binary

```bash
aptos move compile
```


Step 6: deploy smart contract to aptos blockchain

```bash
aptos move pulish
```



