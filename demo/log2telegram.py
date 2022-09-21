# '''
# Created on 2022-09-20

# @author: Alessandro Lovo
# '''
'''
This modules logs a message to telegram

When running from terminal:
```
python log2telegram.py "<message>" [<telegram chat ID> <telegram bot token>] [<telegram logging level>]
```
'''
import sys
import logging

sys.path.append('../')
import general_purpose.utilities as ut

if __name__ == '__main__':
    logger = logging.getLogger()
    logger.handlers = [logging.StreamHandler(sys.stdout)]
else:
    logger = logging.getLogger(__name__)
logger.level = logging.INFO

if __name__ == '__main__':
    logger.debug(str(sys.argv))
    msg = sys.argv[1].strip('"').replace('\\n', '\n')

    # deal with the telegram logger
    th = None
    if len(sys.argv) > 3:
        telegram_chat_ID = sys.argv[2]
        telegram_token = sys.argv[3]
        telegram_logging_level = int(sys.argv[4]) if len(sys.argv) > 4 else logging.INFO

        if logger.level < telegram_logging_level:
            logger.level = telegram_logging_level

        th = ut.new_telegram_handler(telegram_chat_ID, telegram_token, level=telegram_logging_level)

        logger.handlers.append(th)
        logger.debug('Added telegram logger')

    try:
        logger.log(telegram_logging_level,msg)
    finally:
        if th is not None:
            logger.handlers.remove(th)
            logger.info('Removed telegram logger')