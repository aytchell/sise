# Sise

Sise is a library that implements the **si**mple **se**rvice
discovery protocol (SSDP).

Sise implements the Application behaviour and thus automatically starts
operation. In its current state the library is
- listening for announcements (and updates)
- issuing M-Search requests from time to time (interval can be configured)

There is a function available, so you can fetch discovered devices or services
for all, or a specific notification type.

Additionally, processes can subscribe (for all, or a specific notification
type), so they will get notification messages for new, updated or gone
devices and services.

## Documentation

The library's API is documented with ExDoc. See https://hexdocs.pm/sise/
for the latest generated version.

## Usage with mix

```
defp deps do
  [
    {:sise, "~> 0.9.3"}
  ]
end
```

## Contribution

If you have any suggestions for improvements (I'm quite new to Elixir)
then please drop a note or open a PR.

## License

Copyright 2021, Hannes Lerchl

Licensed under the Apache License, Version 2.0

A copy of this License is contained in [this repository](LICENSE.txt) or
alternatively can be obtained from

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
