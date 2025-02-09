import logging

from typing import List

from ..common_neon.solana_tx import SolTx
from ..common_neon.solana_tx_legacy import SolLegacyTx
from ..common_neon.errors import EthereumError, SenderAccountNotExists
from ..common_neon.neon_instruction import EvmIxCodeName, EvmIxCode
from ..common_neon.address import NeonAddress

from .neon_tx_send_base_strategy import BaseNeonTxPrepStage


LOG = logging.getLogger(__name__)


class NewAccountNeonTxPrepStage(BaseNeonTxPrepStage):
    name = EvmIxCodeName().get(EvmIxCode.CreateAccountV03)

    def complete_init(self) -> None:
        pass

    def get_tx_name_list(self) -> List[str]:
        return [self.name]

    def build_tx_list(self) -> List[List[SolTx]]:
        tx_list_list: List[List[SolTx]] = list()
        if self._is_account_exist():
            return tx_list_list

        sender_addr = NeonAddress(self._ctx.neon_tx_info.addr)
        ix = self._ctx.ix_builder.make_create_neon_account_ix(sender_addr)
        tx = SolLegacyTx(self.name, [ix])
        tx_list_list.append([tx])
        return tx_list_list

    def update_after_emulate(self) -> None:
        if not self._is_account_exist():
            raise SenderAccountNotExists(self._ctx.neon_tx_info.addr)

    def _is_account_exist(self) -> bool:
        sender_addr = self._ctx.neon_tx_info.addr
        if self._ctx.is_stuck_tx():
            return True
        elif sender_addr is None:
            raise EthereumError('Sender address is NULL')

        account_info = self._ctx.solana.get_neon_account_info(sender_addr)
        if account_info is None:
            if self._ctx.neon_tx_info.gas_price != 0:
                raise EthereumError('Sender address does not exist')
            return False
        return True
